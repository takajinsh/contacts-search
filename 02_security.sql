-- Step 2: security and allow-list. Safe to run more than once.
create schema if not exists private;

create or replace function private.is_allowed_user()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.app_allowed_user u
    where lower(u.email) = lower(coalesce(auth.jwt()->>'email',''))
  );
$$;

revoke all on public.app_allowed_user from anon, authenticated;
revoke all on function private.is_allowed_user() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.is_allowed_user() to authenticated;

do $$
declare t text;
begin
  foreach t in array array[
    'people','person_aliases','organizations','departments','affiliations',
    'affiliation_contacts','department_contacts','affiliation_sources',
    'interactions','search_aliases'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('revoke all on public.%I from authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('drop policy if exists %I on public.%I', 'allowlisted_read', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using ((select private.is_allowed_user()))',
      'allowlisted_read', t
    );
  end loop;
end
$$;
