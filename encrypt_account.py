import getpass, os
from cryptography.fernet import Fernet
key = os.environ.get("CREDENTIAL_FERNET_KEY")
if not key:
    raise SystemExit("Set CREDENTIAL_FERNET_KEY in your local terminal first.")
fernet = Fernet(key.encode())
account_id = input("Account ID (e.g. account-01): ").strip()
email = input("Account email: ").strip()
password = getpass.getpass("Account password (hidden): ")
if not account_id or not email or not password:
    raise SystemExit("All fields are required.")
print("\nCopy these values into your private Supabase table:")
print("account_id:", account_id)
print("email:", email)
print("password_ciphertext:", fernet.encrypt(password.encode()).decode())
