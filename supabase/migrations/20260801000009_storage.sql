-- CampusPulse: storage buckets + policies
-- Run once against a live project. Bucket creation via SQL requires the
-- storage extension's helper; if your Supabase version does not expose
-- `storage.buckets` writes via SQL, create the buckets in the Dashboard
-- with these exact settings and then apply only the policy statements
-- below.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('event-posters', 'event-posters', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('club-logos', 'club-logos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('certificates', 'certificates', false, 10485760, array['application/pdf'])
on conflict (id) do nothing;

-- event-posters: verified organizers upload for their own club's events
-- (path convention: <club_id>/<event_id>/<uuid>.<ext>); any authenticated
-- user may read (poster visibility for published events is enforced at
-- the events-table level, not the bucket, since drafts also need
-- previewing by their own organizer).
create policy "event_posters_organizer_write" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'event-posters'
    and is_verified_organizer_for_club((storage.foldername(name))[1]::uuid)
  );

create policy "event_posters_organizer_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'event-posters'
    and is_verified_organizer_for_club((storage.foldername(name))[1]::uuid)
  );

create policy "event_posters_authenticated_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'event-posters');

-- club-logos: verified club organizers/admins upload; authenticated read.
create policy "club_logos_organizer_write" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'club-logos'
    and (is_admin() or is_verified_organizer_for_club((storage.foldername(name))[1]::uuid))
  );

create policy "club_logos_authenticated_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'club-logos');

-- certificates: NO client insert/update policy at all — only the
-- issue-certificates Edge Function (service_role) may write. Students may
-- only ever obtain a short-lived signed URL server-side; direct SELECT
-- from the client is also denied so a signed URL is mandatory.
-- (No policy is created for authenticated select on this bucket.)
