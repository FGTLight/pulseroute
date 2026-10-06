-- PulseRoute · 3/7 · Workouts
--
-- Workouts are recorded offline on the device (drift) and uploaded when they
-- finish. The client generates the id, so retrying an upload is idempotent.

create table public.workouts (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  activity public.activity_type not null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  -- Moving time in seconds (pauses excluded).
  duration_s integer not null check (duration_s >= 0),
  distance_m double precision not null check (distance_m >= 0),
  elevation_gain_m double precision not null default 0 check (elevation_gain_m >= 0),
  avg_speed_mps double precision not null default 0 check (avg_speed_mps >= 0),
  max_speed_mps double precision not null default 0 check (max_speed_mps >= 0),
  -- Seconds per completed kilometer, e.g. [312, 305, 298].
  splits_s integer[] not null default '{}',
  route extensions.geography(linestring, 4326),
  created_at timestamptz not null default now(),
  constraint workouts_time_order check (ended_at >= started_at)
);

comment on table public.workouts is 'Finished workouts with their GPS route.';

create index workouts_user_started_idx on public.workouts (user_id, started_at desc);
create index workouts_route_gix on public.workouts using gist (route);

-- Computed fields: PostgREST exposes them as virtual columns, e.g.
--   select=*,route_points  or  select=id,route_preview
-- so the app never has to parse PostGIS binary formats.

-- Full route as [[lat, lng], ...].
create or replace function public.route_points(w public.workouts)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_array(
        round(extensions.st_y(dp.geom)::numeric, 6),
        round(extensions.st_x(dp.geom)::numeric, 6)
      )
      order by dp.path
    ),
    '[]'::jsonb
  )
  from extensions.st_dumppoints(w.route::extensions.geometry) as dp;
$$;

-- Simplified route (~10 m tolerance) for list thumbnails.
create or replace function public.route_preview(w public.workouts)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_array(
        round(extensions.st_y(dp.geom)::numeric, 5),
        round(extensions.st_x(dp.geom)::numeric, 5)
      )
      order by dp.path
    ),
    '[]'::jsonb
  )
  from extensions.st_dumppoints(
    extensions.st_simplify(w.route::extensions.geometry, 0.0001)
  ) as dp;
$$;

-- Row Level Security ---------------------------------------------------------

alter table public.workouts enable row level security;

create policy "Users read their own workouts"
  on public.workouts for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users create their own workouts"
  on public.workouts for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users update their own workouts"
  on public.workouts for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users delete their own workouts"
  on public.workouts for delete
  to authenticated
  using ((select auth.uid()) = user_id);
