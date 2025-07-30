{ pkgs, lib, config, inputs, baseBuildInputs, ... }:
let
  buildInputs = with pkgs; [
    python312
    stdenv.cc.cc
    tesseract
    glib
    openssh
    cmake
    gcc
    pkg-config
    protobuf
    libglvnd
  ];
  runtimePackages = with pkgs; [
    stdenv.cc.cc
    ffmpeg-headless.bin
    tesseract
    uvPackage
    libglvnd # Add libglvnd for libGL.so.1
    glib
    zlib
    ollama.out
  ];

  host = "localhost";
  port = "8182";
  DJANGO_MODULE = "endoreg_db_api";

  # --- Directory Structure ---
  dataDir = "data";
  importDir = "${dataDir}/import";
  importVideoDir = "${importDir}/video";
  importReportDir = "${importDir}/report";
  importLegacyAnnotationDir = "${importDir}/legacy_annotations";
  exportDir = "${dataDir}/export";
  exportFramesRootDir = "${exportDir}/frames";
  exportFramesSampleExportDir = "${exportFramesRootDir}/test_outputs";
  modelDir = "${dataDir}/models";
  confDir = "./conf"; # Define confDir here

  python = pkgs.python312;
  uvPackage = pkgs.uv;

  _module.args.buildInputs = baseBuildInputs;

  endoreg-db-src = pkgs.fetchgit {
    url = "https://github.com/wg-lux/endoreg-db";
    rev = "prototype-release";
    hash = "sha256-/VtN87TPe7GhDJUHKBnozhfSDUzf2E1aBZ/WVAWuzMI=";
    # If you know the specific revision, it's better to use rev for reproducibility
  };


  #nix-prefetch-git https://github.com/wg-lux/lx-anonymizer --rev refs/heads/prototype
  lx-anonymizer-src = pkgs.fetchgit {
    url = "https://github.com/wg-lux/lx-anonymizer";
    rev = "prototype-release";
    hash = "sha256-YUSt1AsTvJE81d0bGLqxK70NNHH+NN8dQ0x5mbiTSc8=";
    # If you know the specific revision, it's better to use rev for reproducibility
    # rev = "abcdef1234567890"; 
  };

  imports = [ 
    "${endoreg-db-src}/devenv.nix"
  ]; 


in 
{

  # A dotenv file was found, while dotenv integration is currently not enabled.
  dotenv.enable = true;
  dotenv.disableHint = true;


  packages = with pkgs; [
    cudaPackages.cuda_nvcc
    stdenv.cc.cc
  ];

  env = {
    LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs + ":/run/opengl-driver/lib:/run/opengl-driver-32/lib";
    # Force uv to use the Nix-provided Python - override any conflicts
    UV_PYTHON = lib.mkForce "${python}/bin/python";
    UV_PYTHON_DOWNLOADS = "never";
    CONF_DIR = "./conf";
  };

  languages.python = {
    enable = true;
    package = python;
    uv = {
      enable = true;
      package = uvPackage;
      sync.enable = true;
    };
  };

  scripts.set-prod-settings.exec = "${pkgs.uv}/bin/uv run python scripts/set_production_settings.py";
  scripts.set-dev-settings.exec = "${pkgs.uv}/bin/uv run python scripts/set_development_settings.py";
  scripts.export-nix-vars.exec = ''
      cat > .devenv-vars.json << EOF
      {
        "DJANGO_MODULE": "${DJANGO_MODULE}",
        "HOST": "${host}",
        "PORT": "${port}",
        "CONF_DIR": "${confDir}",
        "HOME_DIR": "$HOME",
        "WORKING_DIR": "$PWD",
      }
      EOF
      echo "Exported Nix variables to .devenv-vars.json"
    '';

    scripts.env-setup.exec = ''
    export LD_LIBRARY_PATH="${
      with pkgs;
      lib.makeLibraryPath buildInputs
    }:/run/opengl-driver/lib:/run/opengl-driver-32/lib"
    '';


  scripts.hello.exec = "${pkgs.uv}/bin/uv run python hello.py";
  scripts.run-dev-server.exec = ''
    set-dev-settings
    echo "Running dev server"
    echo "Host: ${host}"
    echo "Port: ${port}"
    ${pkgs.uv}/bin/uv run python manage.py runserver ${host}:${port}
  '';

  scripts.run-prod-server.exec = ''
    set-prod-settings
    ${pkgs.uv}/bin/uv run daphne ${DJANGO_MODULE}.asgi:application -p ${port}
  '';

  scripts.init-data.exec = ''
    devenv tasks run deploy:make-migrations
    devenv tasks run deploy:migrate
    devenv tasks run deploy:load-base-db-data
  '';



  scripts.install-api.exec = ''
    set-prod-settings
    devenv tasks run deploy:ensure-psql-user
    devenv tasks run deploy:pipe
    set-dev-settings
  '';


  tasks = {
    
    "deploy:ensure-psql-user" =  {
      exec = "${pkgs.uv}/bin/uv run python scripts/ensure_psql_user.py";
    };

    "deploy:migrate" = { 
      exec = "${pkgs.uv}/bin/uv run python manage.py migrate";
    };
    "deploy:load-base-db-data" = {
      after = ["deploy:migrate"];
      exec = "${pkgs.uv}/bin/uv run python manage.py load_base_db_data";
    };
    "deploy:collectstatic".exec = "${pkgs.uv}/bin/uv run python manage.py collectstatic --noinput";


    "deploy:pipe" = {
      after = ["deploy:collectstatic" "deploy:load-base-db-data"];
      exec = "echo Deployment-Pipeline Completed";
    };

    "test:gpu".exec = "${pkgs.uv}/bin/uv run python gpu-check.py";
    "dev:runserver".exec = "${pkgs.uv}/bin/uv run python manage.py runserver";
    "prod:runserver".exec = "${pkgs.uv}/bin/uv run daphne ${DJANGO_MODULE}.asgi:application -b 172.16.255.142 -p 8123";
    
    "env:psql-pwd-file-exists" ={
      exec = "${pkgs.uv}/bin/uv run python scripts/ensure_psql_pwd_file_exists.py";
    };

    "env:init-conf" = {
      after = ["env:psql-pwd-file-exists" "devenv:enterShell"];
      exec = "${pkgs.uv}/bin/uv run python scripts/make_conf.py";
    };
    "env:build" = {
      description = "Generate/update .env file with secrets and config";
      exec = "export-nix-vars && uv run env_setup.py";
      after = ["devenv:enterShell" "env:init-conf"];
      # status = "test -f .env";
    };
    "env:export" = {
      description = "Export the .env file";
      after = ["env:build"];
      exec = "export $(cat .env | xargs)";
    };
  };

  processes = {
    django.exec = "run-prod-server";
    silly-example.exec = "while true; do echo hello && sleep 10; done";
    # django.exec = "${pkgs.uv}/bin/uv run python manage.py runserver 127.0.0.1:8123";
  };

  enterShell = ''
    # # Create symlinks to the repositories from devenv inputs
    # echo "Setting up repository symlinks..."
    
    # Create symlink for endoreg-db-production
    # Remove existing symlink or directory to ensure it always points to the latest version
    if [ -L "./endoreg-db-production" ] || [ -d "./endoreg-db-production" ]; then
      rm -rf ./endoreg-db-production
    fi
    echo "Creating symlink for endoreg-db-production..."
    ln -sf ${endoreg-db-src} ./endoreg-db-production
    fi
    
    # Create symlink for lx-anonymizer-production  
    if [ ! -e "./lx-anonymizer-production" ]; then
      echo "Creating symlink for lx-anonymizer-production..."
      ln -sf ${lx-anonymizer-src} ./lx-anonymizer-production
    fi
    
    # echo "Repository symlinks are set up."
    
    . .devenv/state/venv/bin/activate

    hello
  '';
}

