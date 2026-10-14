-- Verification query
select
  (select count(*) from information_schema.tables where table_schema='public' and table_name in ('people','person_aliases','organizations','departments','affiliations','affiliation_contacts','department_contacts','affiliation_sources','interactions','search_aliases','app_allowed_user')) as tables_created,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='search_contacts') as search_functions;
