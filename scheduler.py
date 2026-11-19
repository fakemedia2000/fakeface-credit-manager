import os, sys, requests
from datetime import datetime, timedelta, timezone
from cryptography.fernet import Fernet

URL = os.environ["SUPABASE_URL"].rstrip("/")
KEY = os.environ["SUPABASE_SECRET_KEY"]
FERNET_KEY = os.environ["CREDENTIAL_FERNET_KEY"]
HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}

def now(): return datetime.now(timezone.utc)
def iso(v): return v.isoformat()
def rpc(name, payload):
    r = requests.post(f"{URL}/rest/v1/rpc/{name}", headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    return r.json()
def decrypt_password(ciphertext):
    return Fernet(FERNET_KEY.encode()).decrypt(ciphertext.encode()).decode()

class AlreadyClaimed(Exception):
    def __init__(self, eligible_at): self.eligible_at = eligible_at
class ClaimConfirmed(Exception): pass
class LoginTimeout(Exception): pass
class ManualReview(Exception): pass

def fakeface_browser_adapter(email, password):
    # Intentionally unimplemented. No website login or credit claim is performed.
    raise NotImplementedError("Fakeface browser adapter has not been configured.")

def save_result(a, status, next_attempt, next_claim=None, claimed=False, error=None):
    return rpc("release_account", {
        "p_account_id": a["account_id"], "p_lease_token": a["lease_token"],
        "p_status": status, "p_next_attempt_at": iso(next_attempt),
        "p_next_claim_at": iso(next_claim) if next_claim else None,
        "p_claimed": claimed, "p_error": error
    })

def process_account(a):
    password = decrypt_password(a["password_ciphertext"])
    try:
        fakeface_browser_adapter(a["email"], password)
    except ClaimConfirmed:
        due = now() + timedelta(hours=24)
        save_result(a, "claimed", due, due, True)
        print(a["account_id"], "claim confirmed")
    except AlreadyClaimed as e:
        save_result(a, "already_claimed", e.eligible_at, e.eligible_at)
        print(a["account_id"], "already claimed")
    except LoginTimeout:
        save_result(a, "retry", now() + timedelta(minutes=30), error="login_timeout")
        print(a["account_id"], "login timed out; retry in 30 minutes")
    except ManualReview as e:
        save_result(a, "manual_review", now() + timedelta(days=3650), error=str(e))
        print(a["account_id"], "manual review required")
    except NotImplementedError as e:
        save_result(a, "manual_review", now() + timedelta(days=3650), error=str(e))
        raise
    except Exception as e:
        save_result(a, "manual_review", now() + timedelta(days=3650), error=type(e).__name__)
        print(a["account_id"], "requires manual verification")

def main():
    if os.getenv("FAKEFACE_ADAPTER_ENABLED", "false").lower() != "true":
        print("SAFE MODE: adapter disabled; no accounts processed.")
        return 0
    accounts = rpc("lease_due_accounts", {"p_limit": 10, "p_lease_seconds": 900})
    print("Reserved accounts:", len(accounts))
    for a in accounts:
        try: process_account(a)
        except NotImplementedError as e:
            print("Stopping safely:", e)
            break
    return 0

if __name__ == "__main__": sys.exit(main())
