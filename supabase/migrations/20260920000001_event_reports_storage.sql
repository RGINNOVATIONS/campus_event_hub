-- CampusPulse: event-reports storage bucket
-- Stores generated .docx event report documents.
-- Write access is restricted to the service_role (used by the generate-event-report-docx Edge Function).
-- Read access is granted via short-lived signed URLs generated server-side.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'event-reports',
  'event-reports',
  false,
  10485760,
  array['application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
on conflict (id) do nothing;

-- event-reports: NO client insert/update policy at all — only the
-- generate-event-report-docx Edge Function (service_role) may write.
-- Organizers and admins obtain a short-lived signed URL server-side;
-- direct client SELECT is denied so signed URLs are mandatory.
