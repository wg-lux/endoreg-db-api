# import os
# from pathlib import Path


# def main():
#     print("Setup environment")

#     db_pwd_path = Path(os.environ.get("DB_PWD_PATH", "./data/db-pwd"))

#     assert db_pwd_path.exists(), f"Database password file not found: {db_pwd_path}"

#     with open(db_pwd_path, "r") as file:
#         db_pwd = file.read().strip()


# if __name__ == "__main__":
#     main()
