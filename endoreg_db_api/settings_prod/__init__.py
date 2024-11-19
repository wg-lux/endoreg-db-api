import os
from endoreg_db_api.settings_base import (
    BASE_DIR,
    CONF_DIR,
    DEBUG,
    INSTALLED_APPS,
    MIDDLEWARE,
    ROOT_URLCONF,
    TEMPLATES,
    AUTH_PASSWORD_VALIDATORS,
    LANGUAGE_CODE,
    TIME_ZONE,
    USE_I18N,
    USE_TZ,
    STATIC_URL,
    DEFAULT_AUTO_FIELD,
    STATIC_ROOT,
    STATICFILES_DIRS
)

DB_PWD_FILE = os.environ.get("DB_PWD_FILE", f"{CONF_DIR}/db-pwd")
DB_USER_FILE = os.environ.get("DB_USER_FILE", f"{CONF_DIR}/db-user")
DB_HOST_FILE = os.environ.get("DB_HOST_FILE", f"{CONF_DIR}/db-host")
DB_PORT_FILE = os.environ.get("DB_PORT_FILE", f"{CONF_DIR}/db-port")
DB_NAME_FILE = os.environ.get("DB_NAME_FILE", f"{CONF_DIR}/db-name")

SECRET_KEY = 'django-insecure-ehohvfo*#^_blfeo_n$p31v2+&ylp$(1$96d%5!0y(-^l28x-6'
ALLOWED_HOSTS = ["*"]

with open(DB_PWD_FILE, "r") as file:
    DB_PWD = file.read().strip()

with open(DB_USER_FILE, "r") as file:
    DB_USER = file.read().strip()

with open(DB_HOST_FILE, "r") as file:
    DB_HOST = file.read().strip()

with open(DB_PORT_FILE, "r") as file:
    DB_PORT = file.read().strip()


DATABASES = {
    "default": {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'aglnet_base',
        'USER': DB_USER,
        'PASSWORD': DB_PWD,  # Use the loaded password
        'HOST': '172.16.255.1',  # Set to 'localhost' if the server is local
        'PORT': '5432',       # Default PostgreSQL port
    }
}