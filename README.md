# Info

- pulls latest endoreg-db to ./endoreg-db-production

  - run tests endoreg-db by running "test-local-endoreg-db" in this repo
    - changes directory to ./endoreg-db-production
    - activates the devenv of this directory and calls the "runtests" script (defined in endoreg-db's devenv.nix)

- setup configuration by running "init-lxdb-config"
  - runs scripts/make_conf.py
