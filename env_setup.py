from django.core.management.utils import get_random_secret_key
from pathlib import Path
import shutil


SALT = get_random_secret_key()
SECRET_KEY = get_random_secret_key()

template = Path("./conf_template/default.env")
target = Path("./.env")

if not target.exists():
    shutil.copy(template, target)

FOUND_SALT = False
FOUND_SECRET_KEY = False
for line in target.open(mode="r", encoding="utf-8"):
    key, value = line.split("=", 1)

    if key == "DJANGO_SALT":
        FOUND_SALT = True

    if key == "DJANGO_SECRET_KEY":
        FOUND_SECRET_KEY = True

if not FOUND_SECRET_KEY:
    with target.open("a", encoding="utf-8") as f:
        f.write(f'\nDJANGO_SECRET_KEY="{SECRET_KEY}"')

if not FOUND_SALT:
    with target.open("a", encoding="utf-8") as f:
        f.write(f'\nDJANGO_SALT="{SALT}"')
