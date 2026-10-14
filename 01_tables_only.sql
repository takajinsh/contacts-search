-- Step 1: create tables only. Safe to run more than once.
create extension if not exists pg_trgm;

create table if not exists public.app_allowed_user (
  email text primary key,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.people (
  id uuid primary key,
  anchor_serial integer not null,
  surname text,
  given_name text,
  full_name text not null,
  surname_reading text,
  given_reading text,
  researcher_number text,
  researcher_roster boolean not null default false,
  created_from_serials text,
  sync_token text
);
create unique index if not exists people_anchor_serial_uq on public.people(anchor_serial);

create table if not exists public.person_aliases (
  id uuid primary key,
  person_id uuid not null references public.people(id) on delete cascade,
  alias text not null,
  source text,
  sync_token text,
  unique(person_id, alias)
);

create table if not exists public.organizations (
  id uuid primary key,
  name text not null,
  category text,
  prefecture_code text,
  sync_token text
);
create unique index if not exists organizations_name_uq on public.organizations(name);

create table if not exists public.departments (
  id uuid primary key,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  parent_name text,
  name text not null,
  display_name text,
  sync_token text,
  unique(organization_id, parent_name, name)
);

create table if not exists public.affiliations (
  id uuid primary key,
  legacy_serial integer not null unique,
  person_id uuid not null references public.people(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  department_id uuid references public.departments(id) on delete set null,
  raw_department1 text,
  raw_department2 text,
  unit_name text,
  role text,
  rank text,
  is_current boolean not null default true,
  former_affiliation boolean not null default false,
  needs_review boolean not null default false,
  first_registered_on date,
  confirmed_on date,
  last_contact_on date,
  last_contact_type text,
  source_date date,
  source_event text,
  postal_code text,
  address text,
  url text,
  input_by text,
  image_front text,
  image_back text,
  notes text,
  verification_status text,
  search_text text not null default '',
  sync_token text
);
create index if not exists affiliations_current_idx on public.affiliations(is_current);
create index if not exists affiliations_person_idx on public.affiliations(person_id);
create index if not exists affiliations_org_idx on public.affiliations(organization_id);
create index if not exists affiliations_department_idx on public.affiliations(department_id);
create index if not exists affiliations_search_trgm_idx on public.affiliations using gin (search_text gin_trgm_ops);

create table if not exists public.affiliation_contacts (
  id uuid primary key,
  affiliation_id uuid not null references public.affiliations(id) on delete cascade,
  kind text not null check (kind in ('email','phone_main','extension','mobile','url','other')),
  value text not null,
  label text,
  sync_token text,
  unique(affiliation_id, kind, value)
);

create table if not exists public.department_contacts (
  id uuid primary key,
  department_id uuid not null references public.departments(id) on delete cascade,
  kind text not null check (kind in ('email','phone_main','extension','mobile','url','other')),
  value text not null,
  label text,
  confirmed_on date,
  source_note text,
  sync_token text,
  unique(department_id, kind, value)
);

create table if not exists public.affiliation_sources (
  id uuid primary key,
  affiliation_id uuid not null references public.affiliations(id) on delete cascade,
  source_type text not null check (source_type in ('名刺','メール','メディア','その他')),
  source_date date,
  detail text,
  sync_token text,
  unique(affiliation_id, source_type)
);

create table if not exists public.interactions (
  id uuid primary key,
  person_id uuid not null references public.people(id) on delete cascade,
  affiliation_id uuid references public.affiliations(id) on delete set null,
  occurred_on date not null,
  interaction_type text,
  event text,
  note text,
  sync_token text
);
create index if not exists interactions_person_idx on public.interactions(person_id);
create index if not exists interactions_date_idx on public.interactions(occurred_on desc);

create table if not exists public.search_aliases (
  id uuid primary key,
  alias text not null unique,
  expansion text not null,
  sync_token text
);
