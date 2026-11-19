create extension if not exists pgcrypto;
create table if not exists public.fakeface_accounts (
 account_id text primary key, email text not null, password_ciphertext text not null,
 enabled boolean not null default true,
 status text not null default 'pending' check (status in ('pending','claimed','already_claimed','retry','manual_review','disabled')),
 last_claimed_at timestamptz, next_claim_at timestamptz,
 next_attempt_at timestamptz not null default now(),
 failure_count integer not null default 0, last_error text,
 lease_token uuid, lease_until timestamptz, updated_at timestamptz not null default now()
);
create index if not exists fakeface_due_idx on public.fakeface_accounts(next_attempt_at) where enabled = true;
alter table public.fakeface_accounts enable row level security;
revoke all on public.fakeface_accounts from anon, authenticated;
grant all on public.fakeface_accounts to service_role;

create or replace function public.lease_due_accounts(p_limit integer default 10, p_lease_seconds integer default 900)
returns setof public.fakeface_accounts language plpgsql security definer set search_path = public as $$
begin
 return query
 with picked as (
  select account_id from public.fakeface_accounts
  where enabled = true and status <> 'manual_review' and next_attempt_at <= now()
   and (lease_until is null or lease_until < now())
  order by next_attempt_at, account_id for update skip locked
  limit greatest(1, least(p_limit, 10))
 )
 update public.fakeface_accounts a
 set lease_token = gen_random_uuid(),
     lease_until = now() + make_interval(secs => greatest(60, least(p_lease_seconds, 1800))),
     updated_at = now()
 from picked where a.account_id = picked.account_id returning a.*;
end; $$;

create or replace function public.release_account(
 p_account_id text, p_lease_token uuid, p_status text, p_next_attempt_at timestamptz,
 p_next_claim_at timestamptz default null, p_claimed boolean default false, p_error text default null
) returns boolean language plpgsql security definer set search_path = public as $$
declare changed integer;
begin
 if p_status not in ('pending','claimed','already_claimed','retry','manual_review','disabled') then
  raise exception 'Invalid status';
 end if;
 update public.fakeface_accounts
 set status = p_status, next_attempt_at = p_next_attempt_at,
     next_claim_at = coalesce(p_next_claim_at, next_claim_at),
     last_claimed_at = case when p_claimed then now() else last_claimed_at end,
     failure_count = case when p_claimed or p_status = 'already_claimed' then 0
                          when p_status = 'retry' then failure_count + 1 else failure_count end,
     last_error = left(p_error, 200), lease_token = null, lease_until = null, updated_at = now()
 where account_id = p_account_id and lease_token = p_lease_token;
 get diagnostics changed = row_count;
 return changed = 1;
end; $$;

revoke all on function public.lease_due_accounts(integer, integer) from public, anon, authenticated;
grant execute on function public.lease_due_accounts(integer, integer) to service_role;
revoke all on function public.release_account(text, uuid, text, timestamptz, timestamptz, boolean, text) from public, anon, authenticated;
grant execute on function public.release_account(text, uuid, text, timestamptz, timestamptz, boolean, text) to service_role;
