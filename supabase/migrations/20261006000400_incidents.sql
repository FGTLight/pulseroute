-- PulseRoute · 4/7 · Incidents and community votes
--
-- Lifecycle:
--   * A new incident is `active` and expires after 14 days.
--   * Each "confirm" vote refreshes it: expires_at = max(expires_at, now() + 7 days).
--   * It becomes `resolved` when its reporter votes "resolve", or when at
--     least 2 users vote "resolve" and they are not outnumbered by confirmations.
--   * Expired incidents are simply filtered out by every query (no cron needed).

create type public.incident_category as enum (
  'closed_street',
  'dark_area',
  'no_sidewalk',
  'pothole',
  'dangerous_crossing',
  'other'
);

create type public.incident_status as enum ('active', 'resolved');

create type public.incident_vote_type as enum ('confirm', 'resolve');

create table public.incidents (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid default auth.uid()
    references auth.users (id) on delete set null,
  category public.incident_category not null,
  -- 1 = low, 2 = medium, 3 = high.
  severity smallint not null default 2 check (severity between 1 and 3),
  description text not null default '' check (char_length(description) <= 280),
  location extensions.geography(point, 4326) not null,
  -- Plain coordinates, kept in sync automatically. They make Realtime
  -- payloads and list queries easy to read without parsing PostGIS formats.
  lat double precision generated always as
    (extensions.st_y(location::extensions.geometry)) stored,
  lng double precision generated always as
    (extensions.st_x(location::extensions.geometry)) stored,
  -- Area-type reports (e.g. a dark park) are drawn as a circle of this radius.
  radius_m integer check (radius_m between 10 and 1000),
  -- Path inside the `incident-photos` bucket: <user_id>/<uuid>.jpg
  photo_path text,
  status public.incident_status not null default 'active',
  confirmations integer not null default 0,
  resolutions integer not null default 0,
  created_at timestamptz not null default now(),
  last_confirmed_at timestamptz,
  resolved_at timestamptz,
  expires_at timestamptz not null default (now() + interval '14 days')
);

comment on table public.incidents is 'Community reported urban hazards.';

create index incidents_location_gix on public.incidents using gist (location);
create index incidents_active_idx on public.incidents (expires_at) where status = 'active';
create index incidents_reporter_idx on public.incidents (reporter_id);

create table public.incident_votes (
  incident_id uuid not null references public.incidents (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  vote public.incident_vote_type not null,
  created_at timestamptz not null default now(),
  -- One vote per user per incident (a user may change it later).
  primary key (incident_id, user_id)
);

create index incident_votes_user_idx on public.incident_votes (user_id);

-- Recomputes counters, expiry and status after every vote change.
-- SECURITY DEFINER because voters cannot update incidents they do not own.
create or replace function public.apply_incident_vote()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_incident uuid := coalesce(new.incident_id, old.incident_id);
  v_confirmed boolean := false;
begin
  if tg_op <> 'DELETE' then
    v_confirmed := new.vote = 'confirm';
  end if;

  update public.incidents as i
  set
    confirmations = (
      select count(*) from public.incident_votes v
      where v.incident_id = v_incident and v.vote = 'confirm'
    ),
    resolutions = (
      select count(*) from public.incident_votes v
      where v.incident_id = v_incident and v.vote = 'resolve'
    ),
    last_confirmed_at = case when v_confirmed then now() else i.last_confirmed_at end,
    expires_at = case
      when v_confirmed then greatest(i.expires_at, now() + interval '7 days')
      else i.expires_at
    end
  where i.id = v_incident;

  update public.incidents as i
  set status = 'resolved', resolved_at = now()
  where i.id = v_incident
    and i.status = 'active'
    and (
      (i.resolutions >= 2 and i.resolutions >= i.confirmations)
      or exists (
        select 1 from public.incident_votes v
        where v.incident_id = i.id
          and v.user_id = i.reporter_id
          and v.vote = 'resolve'
      )
    );

  return null;
end;
$$;

create trigger incident_votes_apply
  after insert or update or delete on public.incident_votes
  for each row execute function public.apply_incident_vote();

-- Row Level Security ---------------------------------------------------------

alter table public.incidents enable row level security;
alter table public.incident_votes enable row level security;

-- Safety information is public, even before signing in.
create policy "Incidents are public"
  on public.incidents for select
  to anon, authenticated
  using (true);

create policy "Signed-in users report incidents"
  on public.incidents for insert
  to authenticated
  with check (
    (select auth.uid()) = reporter_id
    and status = 'active'
    and confirmations = 0
    and resolutions = 0
  );

create policy "Reporters edit their incidents"
  on public.incidents for update
  to authenticated
  using ((select auth.uid()) = reporter_id)
  with check ((select auth.uid()) = reporter_id);

create policy "Reporters delete their incidents"
  on public.incidents for delete
  to authenticated
  using ((select auth.uid()) = reporter_id);

-- Counters, status and expiry are owned by the vote trigger: reporters can
-- only edit the descriptive columns.
revoke update on public.incidents from authenticated;
grant update (category, severity, description, radius_m, photo_path)
  on public.incidents to authenticated;

create policy "Users read their own votes"
  on public.incident_votes for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- Reporters cannot confirm their own incident, but they can resolve it.
create policy "Users vote once per incident"
  on public.incident_votes for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and (
      vote = 'resolve'
      or not exists (
        select 1 from public.incidents i
        where i.id = incident_id and i.reporter_id = (select auth.uid())
      )
    )
  );

create policy "Users change their own vote"
  on public.incident_votes for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users remove their own vote"
  on public.incident_votes for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Realtime: new and updated incidents are pushed to every connected map.
alter publication supabase_realtime add table public.incidents;
