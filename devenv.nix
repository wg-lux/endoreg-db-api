{ pkgs, lib, config, inputs, ... }:
let
  buildInputs = with pkgs; [
    python311Full
    # cudaPackages.cuda_cudart
    # cudaPackages.cudnn
    stdenv.cc.cc
  ];

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
    DJANGO_DEBUG = "True";
    DJANGO_SETTINGS_MODULE = "${DJANGO_MODULE}.settings_dev";

  };

  languages.python = {
    enable = true;
    uv = {
      enable = true;
      sync.enable = true;
    };
  };

  scripts.hello.exec = "${pkgs.uv}/bin/uv run python hello.py";
  scripts.run-dev-server.exec =
    "${pkgs.uv}/bin/uv run python manage.py runserver localhost:8182";

  scripts.run-prod-server.exec =
    "${pkgs.uv}/bin/uv run daphne ${DJANGO_MODULE}.asgi:application";

  scripts.env-setup.exec = ''
    export CONF_DIR="/var/endoreg-db-api/data"
    export DJANGO_SETTINGS_MODULE="${DJANGO_MODULE}.settings_dev"
    export DJANGO_DEBUG="True"
    export LD_LIBRARY_PATH="${
      with pkgs;
      lib.makeLibraryPath buildInputs
    }:/run/opengl-driver/lib:/run/opengl-driver-32/lib"
  '';

  scripts.init-environment.exec = ''
    uv pip install -e .

    devenv tasks run deploy:make-migrations
    devenv tasks run deploy:migrate
  '';

  scripts.check-psql.exec = ''
    devenv tasks run deploy:ensure-psql-user
  '';

  scripts.init-lxdb-config.exec = ''
    devenv tasks run deploy:init-conf
  '';

  scripts.init-data.exec = ''
    export DJANGO_SETTINGS_MODULE="${DJANGO_MODULE}.settings_prod"
    devenv tasks run deploy:make-migrations
    devenv tasks run deploy:migrate
    devenv tasks run deploy:load-base-db-data
  '';



  scripts.install-api.exec = ''
    init-lxdb-config
    check-psql
    init-data
  '';


  tasks = {
    "deploy:psql-pwd-file-exists".exec = "test -f /var/endoreg-db-api/data/psql_pwd";
    "deploy:init-conf".after = ["deploy:psql-pwd-file-exists"];
    "deploy:init-conf".exec = "${pkgs.uv}/bin/uv run python scripts/make_conf.py";
    "deploy:ensure-psql-user".after = ["devenv:enterShell" "deploy:init-conf"];
    "deploy:ensure-psql-user".exec = "${pkgs.uv}/bin/uv run python scripts/ensure_psql_user.py";
    "deploy:migrate".after = ["deploy:ensure-psql-user"];
    "deploy:migrate".exec = "${pkgs.uv}/bin/uv run python manage.py migrate";
    "deploy:load-base-db-data".exec = "${pkgs.uv}/bin/uv run python manage.py load_base_db_data";
    "deploy:collectstatic".exec = "${pkgs.uv}/bin/uv run python manage.py collectstatic --noinput";


    "deploy:pipe".after = ["deploy:collectstatic" "deploy:load-base-db-data" "deploy:migrate"];
    "deploy:pipe".exec = "echo Deployment-Pipeline Completed";
    "test:gpu".exec = "${pkgs.uv}/bin/uv run python gpu-check.py";
    "dev:runserver".exec = "${pkgs.uv}/bin/uv run python manage.py runserver";
    "prod:runserver".exec = "${pkgs.uv}/bin/uv run daphne ${DJANGO_MODULE}.asgi:application -b 172.16.255.142 -p 8123";
    "env:build" = {
      description = "Build the .env file";
      after = ["devenv:enterShell"];
      exec = "uv run env_setup.py";
      status = "test -f .env && grep -q 'DJANGO_SECRET_KEY=' .env";
    };
    "env:export" = {
      description = "Export the .env file";
      after = ["env:build"];
      exec = "export $(cat .env | xargs)";
    };
  };

  processes = {
    django.exec = "run-dev-server";
    silly-example.exec = "while true; do echo hello && sleep 10; done";
    # django.exec = "${pkgs.uv}/bin/uv run python manage.py runserver 127.0.0.1:8123";
  };

  enterShell = ''
    . .devenv/state/venv/bin/activate
    init-environment

    hello
  '';
}

