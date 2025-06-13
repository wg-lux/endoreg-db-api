# Info

## Run in Production

### Requirements

- running psql instance using default port
- sudo privileges

### Setup

- make sure that we use the production settins in our .env file: `DJANGO_SETTINGS_MODULE=endo_ai.settings_prod`
- run `install-api`
  - requires to manually enter admin pwd!
- connect to local postgres db using credentials at: ./conf/db.yaml
- make sure file permissions for this file are hardened as it currently stores the raw db
