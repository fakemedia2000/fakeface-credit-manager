-- Run this only AFTER creating your dashboard user in Supabase Authentication.
-- Replace the UUID below with that user's actual Auth user ID.

begin;

-- Restrict the authenticated role to only the non-secret columns needed by the dashboard.
revoke all on table public.fakeface_accounts from anon, authenticated;
grant select (
  account_id,
  enabled,
  status,
  last_claimed_at,
  next_claim_at,
  next_attempt_at,
  failure_count,
  last_error,
  credits_balance,
  credits_checked_at,
  updated_at
) on table public.fakeface_accounts to authenticated;

-- Remove any earlier dashboard policy with this name, then recreate it.
drop policy if exists "dashboard_admin_read_accounts" on public.fakeface_accounts;
create policy "dashboard_admin_read_accounts"
on public.fakeface_accounts
for select
to authenticated
using (auth.uid() = 'REPLACE_WITH_AUTH_USER_UUID'::uuid);

-- A safe read-only view. It intentionally excludes email and password_ciphertext.
create or replace view public.dashboard_accounts
with (security_invoker = true)
as
select
  account_id,
  enabled,
  status,
  last_claimed_at,
  next_claim_at,
  next_attempt_at,
  failure_count,
  last_error,
  credits_balance,
  credits_checked_at,
  updated_at
from public.fakeface_accounts;

grant select on public.dashboard_accounts to authenticated;
revoke all on public.dashboard_accounts from anon;

commit;
