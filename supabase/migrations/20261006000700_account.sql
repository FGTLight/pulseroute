-- PulseRoute · 7/7 · Account deletion
--
-- Lets a signed-in user delete their account (required by app stores).
-- Cascades remove their profile, workouts and votes; their incidents stay
-- (they are community safety data) but lose the reporter reference.
--
-- Note: Supabase blocks deleting Storage objects from SQL, so the app removes
-- the user's photos through the Storage API before calling this function.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
