-- Search RPC. Frontend sends already-expanded terms, e.g. ["千葉", "生活安全総務課"].
create or replace function public.search_contacts(
  p_terms text[],
  p_include_history boolean default false,
  p_limit integer default 80
)
returns table (
  person_id uuid,
  affiliation_id uuid,
  full_name text,
  surname_reading text,
  given_reading text,
  organization text,
  department text,
  unit_name text,
  role text,
  rank text,
  legacy_serial integer,
  is_current boolean,
  last_contact_on date,
  source_event text,
  emails jsonb,
  phones jsonb,
  shared_contacts jsonb
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    p.id,
    a.id,
    p.full_name,
    p.surname_reading,
    p.given_reading,
    o.name,
    coalesce(d.display_name,''),
    coalesce(a.unit_name,''),
    coalesce(a.role,''),
    coalesce(a.rank,''),
    a.legacy_serial,
    a.is_current,
    a.last_contact_on,
    coalesce(a.source_event,''),
    coalesce((select jsonb_agg(jsonb_build_object('value',c.value,'label',c.label) order by c.value)
              from public.affiliation_contacts c where c.affiliation_id=a.id and c.kind='email'),'[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('kind',c.kind,'value',c.value,'label',c.label) order by c.kind,c.value)
              from public.affiliation_contacts c where c.affiliation_id=a.id and c.kind in ('phone_main','extension','mobile')),'[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('kind',dc.kind,'value',dc.value,'label',dc.label,'source_note',dc.source_note) order by dc.kind,dc.value)
              from public.department_contacts dc where dc.department_id=a.department_id),'[]'::jsonb)
  from public.affiliations a
  join public.people p on p.id=a.person_id
  left join public.organizations o on o.id=a.organization_id
  left join public.departments d on d.id=a.department_id
  where (p_include_history or a.is_current)
    and (coalesce(array_length(p_terms,1),0)=0 or not exists (
      select 1 from unnest(p_terms) term
      where trim(term)<>'' and a.search_text not ilike '%'||trim(term)||'%'
    ))
  order by a.is_current desc, a.last_contact_on desc nulls last, p.full_name, a.legacy_serial desc
  limit least(greatest(coalesce(p_limit,80),1),200);
$$;
revoke all on function public.search_contacts(text[], boolean, integer) from public, anon;
grant execute on function public.search_contacts(text[], boolean, integer) to authenticated;
