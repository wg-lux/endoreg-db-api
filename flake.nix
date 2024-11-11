{
  description = "Flake for the endoreg-db-api django server";

  nixConfig = {
    substituters = [
        "https://cache.nixos.org"
      ];
    trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    extra-substituters = "https://cache.nixos.org https://nix-community.cachix.org";
    extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";


    cachix = {
      url = "github:cachix/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, poetry2nix, ... } @ inputs: 
  let 
    system = "x86_64-linux";
    self = inputs.self;
    version = "0.1.${pkgs.lib.substring 0 8 inputs.self.lastModifiedDate}.${inputs.self.shortRev or "dirty"}";
    python-version = "311";
    cachix = inputs.cachix;

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    lib = pkgs.lib;

    pypkgs-build-requirements = {
      django-flat-theme = [ "setuptools" ];
      django-flat-responsive = [ "setuptools" ];
    };

    poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs;};

    p2n-overrides = poetry2nix.defaultPoetryOverrides.extend (final: prev:
      builtins.mapAttrs (package: build-requirements:
        (builtins.getAttr package prev).overridePythonAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ (
            builtins.map (pkg:
              if builtins.isString pkg then builtins.getAttr pkg prev else pkg
            ) build-requirements
          );
        })
      ) pypkgs-build-requirements
    );

    poetryApp = poetry2nix.mkPoetryApplication {
      projectDir = ./.;
      src = lib.cleanSource ./.;
      python = pkgs."python${python-version}";
      overrides = p2n-overrides;
      preferWheels = true; # some packages, e.g. transformers break if false
      propagatedBuildInputs =  with pkgs."python${python-version}Packages"; [
        
      ];
      nativeBuildInputs = with pkgs."python${python-version}Packages"; [
        pip
        setuptools
      ];
      buildInputs = with pkgs; [
        poetry
        python311Packages.venvShellHook
      ];

      venvDir = ".venv";
    };

    poetryEnv = poetry2nix.mkPoetryEnv {
      projectDir = ./.;
      python = pkgs."python${python-version}";
      extraPackages = (ps: [
        ps.pip
      ]);
      overrides = p2n-overrides;
      editablePackageSources = {};
      preferWheels = true;
    };
    
  in
  {

    packages.x86_64-linux.poetryApp = poetryApp;
    packages.x86_64-linux.default = poetryApp;
    
    apps.x86_64-linux.endoreg-db-api = {
      type = "app";
      program = "${poetryApp}/bin/run-endoreg-db-api";
      # program = "${poetryApp}/bin/run-server";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.endoreg-db-api;
  
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        pkgs.poetry
        poetryEnv
        pkgs.python311Packages.numpy
        pkgs.python311Packages.venvShellHook
      ];

      propagatedBuildInputs = [
        pkgs.python311Packages.psycopg
      ];

      venvDir = ".venv";

      # Define Environment Variables
      DJANGO_SETTINGS_MODULE = "endoreg_db_api.endoreg_db_api.settings_base";
      DJANGO_DATA_DIR = "/var/lib/endoreg-db-api";
    };

    nixosModules = {
      endoreg-db-api = { config, pkgs, lib, ...}: 
        let
          mkOption = lib.mkOption;
        in
      {
        
        options.services.endoreg-db-api = {

          enable = mkOption {
            default = true;
            description = "Enable the endoreg-db-api service";
            type = lib.types.bool;
          };

          user = mkOption {
            default = "root";
            description = "The user to run the endoreg-db-api service as";
            type = lib.types.str;
          };

          group = mkOption {
            default = "root";
            description = "The group to run the endoreg-db-api service as";
            type = lib.types.str;
          };

          ip = mkOption {
            default = "127.0.0.1";
            description = "The ip to run the endoreg-db-api service on";
            type = lib.types.str;
          };

          port = mkOption {
            default = 8000;
            description = "The port to run the endoreg-db-api service on";
            type = lib.types.int;
          };

          target-db-host = mkOption {
            default = "localhost";
            description = "The target database host to connect to";
            type = lib.types.str;
          };

          target-db-port = mkOption {
            default = 5432;
            description = "The target database port to connect to";
            type = lib.types.int;
          };

          target-db = mkOption {
            default = "endoreg-db";
            description = "The target database to connect to";
            type = lib.types.str;
          };

          target-db-user = mkOption {
            default = "endoreg-db";
            description = "The target database user to connect as";
            type = lib.types.str;
          };

          target-db-passfile = mkOption {
            default = "/etc/aglnet-base-db_pass";
            description = "The target database password file";
            type = lib.types.str;
          };

        };

        # if endoreg-db-api service is enabled, add the poetryApp to the systemPackages
        config = lib.mkIf config.endoreg-db-api.enable {
          environment.systemPackages = [ 
            poetryApp
            pkgs.openssl
            pkgs.lsof
          ];
        
        # if endoreg-db-api service is enabled, we need to start the wsgi application using gunicorn
        systemd.services.endoreg-db-api = {
          description = "endoreg-db-api service";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            User = config.endoreg-db-api.user;
            Group = config.endoreg-db-api.group;
            ExecStart = "${poetryApp}/bin/run-endoreg-db-api";
            Environment = {
              DJANGO_SETTINGS_MODULE = "endoreg_db_api.endoreg_db_api.settings_base";
              DJANGO_DATA_DIR = "/var/lib/endoreg-db-api";
              DJANGO_DB_HOST = config.endoreg-db-api.target-db-host;
              DJANGO_DB_PORT = "${toString config.endoreg-db-api.target-db-port}";
              DJANGO_DB_NAME = config.endoreg-db-api.target-db;
              DJANGO_DB_USER = config.endoreg-db-api.target-db-user;
              DJANGO_DB_PASS = "${pkgs.readFile config.endoreg-db-api.target-db-passfile}";
            };
            Restart = "always";
          }; 


        };

        };
      };

    };

  };


}