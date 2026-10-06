-- PulseRoute · 1/7 · Extensions and shared helpers
--
-- PostGIS powers every geo query (ST_DWithin on geography uses meters).
-- Supabase recommends installing extensions in the `extensions` schema.

create extension if not exists postgis with schema extensions;

-- Keeps `updated_at` columns current.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
