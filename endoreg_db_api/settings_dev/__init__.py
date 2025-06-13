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
    STATIC_ROOT,
    DEFAULT_AUTO_FIELD,
    STATICFILES_DIRS,
)

DEBUG = True
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# ALLOWED_HOSTS = ["*"]
ALLOWED_HOSTS = ["localhost", "127.0.0.1"]
