{ pkgs, lib, config, inputs, ... }:
let
  buildInputs = with pkgs; [
    python311Full
    # cudaPackages.cuda_cudart
    # cudaPackages.cudnn
    stdenv.cc.cc
  ];

  host = "localhost";
  port = "8182";
  DJANGO_MODULE = "endoreg_db_api";

in 
{

  # A dotenv file was found, while dotenv integration is currently not enabled.
  dotenv.enable = false;
  dotenv.disableHint = true;


  packages = with pkgs; [
    cudaPackages.cuda_nvcc
    stdenv.cc.cc
  ];

  env = {
    LD_LIBRARY_PATH = "${
      with pkgs;
      lib.makeLibraryPath buildInputs
    }:/run/opengl-driver/lib:/run/opengl-driver-32/lib";
    CONF_DIR = "./conf";
  };

  languages.python = {
    enable = true;
    uv = {
      enable = true;
      sync.enable = true;
    };
  };

  scripts.set-prod-settings.exec = "${pkgs.uv}/bin/uv run python scripts/set_production_settings.py";
  scripts.set-dev-settings.exec = "${pkgs.uv}/bin/uv run python scripts/set_development_settings.py";

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
      description = "Build the .env file";
      after = ["devenv:enterShell" "env:init-conf"];
      exec = "uv run env_setup.py";
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
    . .devenv/state/venv/bin/activate

    hello
  '';
}

