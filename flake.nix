{
  description = "Hello world flake using uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:adisbladis/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
  # It's using https://nix-community.github.io/pyproject.nix/build.html

  outputs =
    {
      self,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      asgiApp = "endoreg_db_api.asgi:application";
      settingsModules = {
        prod = "endoreg_db_api.settings";
      };

      # Load a uv workspace from a workspace root.
      # Uv2nix treats all uv projects as workspace projects.
      # https://adisbladis.github.io/uv2nix/lib/workspace.html
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      # Create package overlay from workspace.
      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel"; # or sourcePreference = "sdist";
      };

      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };

      # Python sets grouped per system
      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) stdenv;

          # Base Python package set from pyproject.nix
          baseSet = pkgs.callPackage pyproject-nix.build.packages {
            python = pkgs.python312;
          };

          # An overlay of build fixups & test additions
          pyprojectOverrides = final: prev: {

            endoreg-db-api = prev.endoreg-db-api.overrideAttrs (old: {

              # Add tests to passthru.tests
              #
              # These attribute are used in Flake checks.
              passthru = old.passthru // {
                tests =
                  (old.tests or { })
                  // {

                    # Run mypy checks
                    mypy =
                      let
                        venv = final.mkVirtualEnv "endoreg-db-api-typing-env" {
                          endoreg-db-api = [ "typing" ];
                        };
                      in
                      stdenv.mkDerivation {
                        name = "${final.endoreg-db-api.name}-mypy";
                        inherit (final.endoreg-db-api) src;
                        nativeBuildInputs = [
                          venv
                        ];
                        dontConfigure = true;
                        dontInstall = true;
                        buildPhase = ''
                          mkdir $out
                          mypy --strict . --junit-xml $out/junit.xml
                        '';
                      };

                    # Run pytest with coverage reports installed into build output
                    pytest =
                      let
                        venv = final.mkVirtualEnv "endoreg-db-api-pytest-env" {
                          endoreg-db-api = [ "test" ];
                        };
                      in
                      stdenv.mkDerivation {
                        name = "${final.endoreg-db-api.name}-pytest";
                        inherit (final.endoreg-db-api) src;
                        nativeBuildInputs = [
                          venv
                        ];

                        dontConfigure = true;

                        buildPhase = ''
                          runHook preBuild
                          pytest --cov tests --cov-report html tests
                          runHook postBuild
                        '';

                        installPhase = ''
                          runHook preInstall
                          mv htmlcov $out
                          runHook postInstall
                        '';
                      };
                  }
                  // lib.optionalAttrs stdenv.isLinux {

                    # NixOS module test
                    nixos =
                      let
                        venv = final.mkVirtualEnv "endoreg-db-api-nixos-test-env" {
                          endoreg-db-api = [ ];
                        };
                      in
                      pkgs.nixosTest {
                        name = "endoreg-db-api-nixos-test";

                        nodes.machine =
                          { ... }:
                          {
                            imports = [
                              self.nixosModules.endoreg-db-api
                            ];

                            services.endoreg-db-api = {
                              enable = true;
                              inherit venv;
                            };

                            system.stateVersion = "24.11";
                          };

                        testScript = ''
                          machine.wait_for_unit("endoreg-db-api.service")

                          with subtest("Web interface getting ready"):
                              machine.wait_until_succeeds("curl -fs localhost:8000")
                        '';
                      };

                  };
              };
            });

          };

        in
        baseSet.overrideScope (lib.composeExtensions overlay pyprojectOverrides)
      );

      # Django static roots grouped per system
      staticRoots = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) stdenv;

          pythonSet = pythonSets.${system};

          venv = pythonSet.mkVirtualEnv "endoreg-db-api-env" workspace.deps.default;

        in
        stdenv.mkDerivation {
          name = "endoreg-db-api-static";
          inherit (pythonSet.endoreg-db-api) src;

          dontConfigure = true;
          dontBuild = true;

          nativeBuildInputs = [
            venv
          ];

          installPhase = ''
            env DJANGO_STATIC_ROOT="$out" python manage.py collectstatic
          '';
        }
      );

    in
    {
      checks = forAllSystems (
        system:
        let
          pythonSet = pythonSets.${system};
        in
        # Inherit tests from passthru.tests into flake checks
        pythonSet.endoreg-db-api.passthru.tests
      );

      nixosModules = {
        endoreg-db-api =
          {
            config,
            lib,
            pkgs,
            ...
          }:

          let
            cfg = config.services.endoreg-db-api;
            inherit (pkgs) system;

            pythonSet = pythonSets.${system};

            inherit (lib.options) mkOption;
            inherit (lib.modules) mkIf;
          in
          {
            options.services.endoreg-db-api = {
              enable = mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Enable endoreg-db-api
                '';
              };

              settings-module = mkOption {
                type = lib.types.string;
                default = settingsModules.prod;
                description = ''
                  Django settings module
                '';
              };

              venv = mkOption {
                type = lib.types.package;
                default = pythonSet.mkVirtualEnv "endoreg-db-api-env" workspace.deps.default;
                description = ''
                  endoreg-db-api virtual environment package
                '';
              };

              static-root = mkOption {
                type = lib.types.package;
                default = staticRoots.${system};
                description = ''
                  endoreg-db-api static root
                '';
              };
            };

            config = mkIf cfg.enable {
              systemd.services.endoreg-db-api = {
                description = "Django Webapp server";

                environment.DJANGO_STATIC_ROOT = cfg.static-root;

                serviceConfig = {
                  ExecStart = ''
                    ${cfg.venv}/bin/daphne endoreg_db_api.asgi:application
                  '';
                  Restart = "on-failure";

                  DynamicUser = true;
                  StateDirectory = "endoreg-db-api";
                  RuntimeDirectory = "endoreg-db-api";

                  BindReadOnlyPaths = [
                    "${
                      config.environment.etc."ssl/certs/ca-certificates.crt".source
                    }:/etc/ssl/certs/ca-certificates.crt"
                    builtins.storeDir
                    "-/etc/resolv.conf"
                    "-/etc/nsswitch.conf"
                    "-/etc/hosts"
                    "-/etc/localtime"
                  ];
                };

                wantedBy = [ "multi-user.target" ];
              };
            };

          };

      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system};
        in
        lib.optionalAttrs pkgs.stdenv.isLinux {
          # Expose Docker container in packages
          docker =
            let
              venv = pythonSet.mkVirtualEnv "endoreg-db-api-env" workspace.deps.default;
            in
            pkgs.dockerTools.buildLayeredImage {
              name = "endoreg-db-api";
              contents = [ pkgs.cacert ];
              config = {
                Cmd = [
                  "${venv}/bin/daphne"
                  asgiApp
                ];
                Env = [
                  "DJANGO_SETTINGS_MODULE=${settingsModules.prod}"
                  "DJANGO_STATIC_ROOT=${staticRoots.${system}}"
                ];
              };
            };
        }
      );

      # Use an editable Python set for development.
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          editablePythonSet = pythonSets.${system}.overrideScope editableOverlay;
          venv = editablePythonSet.mkVirtualEnv "endoreg-db-api-dev-env" {
            endoreg-db-api = [ "dev" ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              venv
              pkgs.uv
            ];
            # env.REPO_ROOT = "/home/adisbladis/sauce/github.com/adisbladis/uv2nix/templates/django-webapp";
            # env.REPO_ROOT = "${workspace.root}";
            env.REPO_ROOT = "/home/setup-user/dev/endoreg-db-api";

            shellHook = ''
              unset PYTHONPATH
              # export REPO_ROOT=$(git rev-parse --show-toplevel)
              export UV_NO_SYNC=1
            '';
          };
          impure = pkgs.mkShell {
            packages = [
              pkgs.python312
              pkgs.uv
            ];
            shellHook = ''
              unset PYTHONPATH
            '';
          };
        }
      );

    };
}
