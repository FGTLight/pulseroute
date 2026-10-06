-- PulseRoute · 6/7 · Storage for incident photos
--
-- Public bucket (photos are part of public safety info). Files are stored as
-- <user_id>/<uuid>.jpg and only their uploader can change or delete them.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'incident-photos',
  'incident-photos',
  true,
  2 * 1024 * 1024, -- 2 MB; the app resizes and compresses before uploading
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "Incident photos are public"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'incident-photos');

create policy "Users upload photos to their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'incident-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users update their own photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'incident-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users delete their own photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'incident-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
