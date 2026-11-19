# Fakeface Credit Scheduler — starter scaffold

This is a safe starter scaffold, **not a finished Fakeface integration**. The browser adapter is intentionally unimplemented and disabled. The first workflow run only checks that GitHub Actions and the Python environment start; it does not log in or claim credits.

Before enabling automation, confirm the site's written rules explicitly permit the intended accounts, persistent sessions, and GitHub-hosted runners. Never bypass CAPTCHA, MFA, rate limits, or security checks. Keep passwords and keys out of repository files and chat.

Files:
- `.github/workflows/scheduler.yml`: runs twice hourly in Asia/Kolkata.
- `database/schema.sql`: Supabase table and lease functions.
- `scheduler.py`: safe-mode scheduler scaffold.
- `encrypt_account.py`: local password-encryption helper.
- `requirements.txt`: dependencies.

Do not change `FAKEFACE_ADAPTER_ENABLED` to true: the actual site adapter has not been built or tested.
