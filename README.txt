FAKEFACE DASHBOARD - GITHUB PAGES + SUPABASE AUTH

1. Upload the contents of this package's dashboard folder to a folder named dashboard/ in your GitHub repository. The path must be dashboard/index.html.
2. In Supabase > Authentication > Users, create your own dashboard login user. Confirm/save the user and copy its User UID.
3. In Supabase > Project Settings > API Keys, copy the Project URL and the Publishable key (sb_publishable_...). Do NOT use the secret key in the webpage.
4. Edit dashboard/index.html in GitHub. Replace:
   PASTE_YOUR_SUPABASE_PROJECT_URL_HERE
   PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE
   with the actual Project URL and publishable key. These values are intended for browser use; security comes from Auth + RLS, not from hiding the publishable key.
5. Edit database/dashboard_security.sql and replace REPLACE_WITH_AUTH_USER_UUID with the Auth user's actual User UID. Run the complete SQL in Supabase SQL Editor.
6. In Supabase Authentication > URL Configuration, add your GitHub Pages URL to Site URL and Redirect URLs. Example: https://YOUR-GITHUB-USERNAME.github.io/fakeface-credit-manager/
7. In GitHub repository Settings > Pages, choose Deploy from a branch, branch main, folder / (root), Save.
8. Open the published URL and sign in using the Auth user created in step 2.

SECURITY NOTES
- Never place SUPABASE_SECRET_KEY, account passwords, or password_ciphertext in dashboard/index.html.
- The SQL grants authenticated users only column-level read access and uses an RLS policy bound to one Auth user UUID. Do not add a broad authenticated read policy.
- This dashboard is read-only. It does not perform Fakeface logins or claims.
- Credits remain blank until a separately implemented and tested browser adapter records real balances in credits_balance and credits_checked_at.
- Keep the GitHub repository private if possible. GitHub Pages site content is public even when repository visibility is private, depending on plan/settings; do not put secrets in the site files.
