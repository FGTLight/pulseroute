-- PulseRoute · 5/7 · Geo queries (RPC)
--
-- All distances are in meters: ST_DWithin on geography is accurate on the
-- spheroid and uses the GIST indexes created in the previous migrations.

-- Parameters are qualified with the function name (e.g. incidents_nearby.lat)
-- because they share names with columns of `incidents`.

-- Shape returned by every incident query.
create type public.incident_result as (
  id uuid,
  reporter_id uuid,
  category public.incident_category,
  severity smallint,
  description text,
  lat double precision,
  lng double precision,
  radius_m integer,
  photo_path text,
  status public.incident_status,
  confirmations integer,
  resolutions integer,
  created_at timestamptz,
  expires_at timestamptz,
  distance_m double precision
);

-- Active incidents within `radius_m` of a point, nearest first.
-- Called as: supabase.rpc('incidents_nearby', {lat, lng, radius_m})
create or replace function public.incidents_nearby(
  lat double precision,
  lng double precision,
  radius_m double precision default 2000
)
returns setof public.incident_result
language sql
stable
set search_path = ''
as $$
  with origin as (
    select extensions.st_setsrid(
      extensions.st_makepoint(incidents_nearby.lng, incidents_nearby.lat), 4326
    )::extensions.geography as g
  )
  select
    i.id, i.reporter_id, i.category, i.severity, i.description,
    i.lat, i.lng, i.radius_m, i.photo_path, i.status,
    i.confirmations, i.resolutions, i.created_at, i.expires_at,
    extensions.st_distance(i.location, o.g) as distance_m
  from public.incidents i, origin o
  where i.status = 'active'
    and i.expires_at > now()
    and extensions.st_dwithin(
      i.location, o.g, least(incidents_nearby.radius_m, 50000)
    )
  order by distance_m
  limit 500;
$$;

-- Active incidents within `buffer_m` of a route (a LINESTRING geography,
-- e.g. 'SRID=4326;LINESTRING(lng lat, lng lat, ...)').
create or replace function public.incidents_along_route(
  route extensions.geography,
  buffer_m double precision default 50
)
returns setof public.incident_result
language sql
stable
set search_path = ''
as $$
  select
    i.id, i.reporter_id, i.category, i.severity, i.description,
    i.lat, i.lng, i.radius_m, i.photo_path, i.status,
    i.confirmations, i.resolutions, i.created_at, i.expires_at,
    extensions.st_distance(i.location, incidents_along_route.route) as distance_m
  from public.incidents i
  where i.status = 'active'
    and i.expires_at > now()
    and extensions.st_dwithin(
      i.location,
      incidents_along_route.route,
      least(incidents_along_route.buffer_m, 1000)
    )
  order by distance_m
  limit 200;
$$;

-- Incidents near a stored workout route, including ones that were resolved
-- or expired since (the user saw them during the workout).
-- Runs with the caller's permissions, so RLS limits it to their own workouts.
create or replace function public.incidents_for_workout(
  workout_id uuid,
  buffer_m double precision default 50
)
returns setof public.incident_result
language sql
stable
set search_path = ''
as $$
  select
    i.id, i.reporter_id, i.category, i.severity, i.description,
    i.lat, i.lng, i.radius_m, i.photo_path, i.status,
    i.confirmations, i.resolutions, i.created_at, i.expires_at,
    extensions.st_distance(i.location, w.route) as distance_m
  from public.workouts w
  join public.incidents i
    on extensions.st_dwithin(
      i.location, w.route, least(incidents_for_workout.buffer_m, 1000)
    )
  where w.id = incidents_for_workout.workout_id
    and i.created_at <= w.ended_at
    and (i.resolved_at is null or i.resolved_at >= w.started_at)
  order by distance_m
  limit 200;
$$;

grant execute on function public.incidents_nearby(double precision, double precision, double precision)
  to anon, authenticated;
grant execute on function public.incidents_along_route(extensions.geography, double precision)
  to anon, authenticated;
grant execute on function public.incidents_for_workout(uuid, double precision)
  to authenticated;
