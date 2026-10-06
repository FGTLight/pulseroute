-- PulseRoute · 2/7 · Profiles
--
-- One row per auth user, created automatically on sign up.

create type public.activity_type as enum ('run', 'bike');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 50),
  preferred_activity public.activity_type not null default 'run',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Public profile of each user.';

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Creates the profile from the metadata sent with supabase.auth.signUp().
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := nullif(trim(new.raw_user_meta_data ->> 'display_name'), '');
  v_activity text := new.raw_user_meta_data ->> 'preferred_activity';
begin
  insert into public.profiles (id, display_name, preferred_activity)
  values (
    new.id,
    left(coalesce(v_name, split_part(new.email, '@', 1), 'Runner'), 50),
    case
      when v_activity in ('run', 'bike') then v_activity::public.activity_type
      else 'run'::public.activity_type
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security ---------------------------------------------------------

alter table public.profiles enable row level security;

-- Display names are shown next to incidents, so signed-in users can read them.
create policy "Profiles are readable by signed-in users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
