from pydantic import BaseModel
from typing import Optional
import yaml
from pathlib import Path
from icecream import ic
from typing import Union


class DbConfig(BaseModel):
    engine: str = "django.db.backends.postgresql"
    host: str
    port: int
    user: str
    password: Optional[str] = None
    password_file: str = "/etc/secrets/vault/SCRT_local_password_maintenance_password"
    name: str

    # class options should allow for unused excess data

    @classmethod
    def from_file(cls, path: Union[Path, str]) -> "DbConfig":
        if isinstance(path, str):
            filepath = Path(path)
        else:
            filepath = path
        assert filepath.exists(), f"Missing Config {filepath}"

        with open(filepath) as f:
            cfg = yaml.safe_load(f)

        obj = cls(**cfg)

        return obj

    def sync_password(self):
        with open(self.password_file, "r") as f:
            self.password = f.read().strip()

    def validate(self):
        self.sync_password()

        assert self.host, "Missing Host"
        assert self.port, "Missing Port"
        assert self.user, "Missing User"
        assert self.password, "Missing Password"
        assert self.name, "Missing Database"

    def to_file(self, target: str = "./conf/db.yml", ask_override: bool = True):
        ic(target)

        with open(target, "w") as f:
            yaml.safe_dump(self.model_dump(), f)
