#!/usr/bin/env bash

DB_YAML="./conf_template/db.yaml"
PASSWORD_FILE=$(grep "^password_file:" "$DB_YAML" | awk '{print $2}')

if [ ! -f "$PASSWORD_FILE" ]; then
  mkdir -p "$(dirname "$PASSWORD_FILE")"
  tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1 > "$PASSWORD_FILE"
  echo "Password file created at $PASSWORD_FILE."
else
  echo "Password file already exists at $PASSWORD_FILE."
fi

