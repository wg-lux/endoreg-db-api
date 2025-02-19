import os
from endoreg_db_api.utils import DbConfig
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
    STATICFILES_DIRS,
    CORS_ALLOWED_ORIGINS,  # by gc-08,need to delete after testing/correcting them
    CORS_ALLOW_CREDENTIALS,
    CSRF_TRUSTED_ORIGINS,
    CORS_ALLOW_METHODS,
    CORS_ALLOW_HEADERS,
)

DB_CFG_FILE = CONF_DIR / "db.yaml"

SECRET_KEY = "django-insecure-ehohvfo*#^_blfeo_n$p31v2+&ylp$(1$96d%5!0y(-^l28x-6"
ALLOWED_HOSTS = ["*"]


db_config: DbConfig = DbConfig.from_file(DB_CFG_FILE)

DATABASES = {
    "default": {
        "ENGINE": db_config.engine,
        "NAME": db_config.name,
        "USER": db_config.user,
        "PASSWORD": db_config.password,
        "HOST": db_config.host,
        "PORT": str(db_config.port),
    }
}


#by gc-08 need to delete after trying
# Import base settings
'''from endoreg_db_api.settings_base import *

# Now explicitly add CORS and CSRF settings
CORS_ALLOWED_ORIGINS = [
    "http://127.0.0.1:5174",
    "http://127.0.0.1:5174/api/patients"

]

CORS_ALLOW_CREDENTIALS = True

CSRF_TRUSTED_ORIGINS = [
    "http://127.0.0.1:5174",
    "http://127.0.0.1:5174/api/patients",

]

CORS_ALLOW_METHODS = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
CORS_ALLOW_HEADERS = ["Content-Type", "Authorization", "X-CSRFToken"]
'''