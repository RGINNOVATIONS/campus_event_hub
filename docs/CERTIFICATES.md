# Certificates

## Workflow

1. Organizer scans QR codes during the event → `mark_event_attendance()`
   flips `enrolments.attendance_status` to `attended` (server-side only,
   see `docs/SECURITY.md`).
2. Organizer marks the event **Completed** (`EventManagementScreen` →
   confirmation dialog → `events.status = 'completed'`).
3. Organizer taps **Issue Certificates**, which calls the
   `issue-certificates` Edge Function with `{ event_id }`.
4. The function (using `service_role`, bypassing RLS by design):
   - re-checks the event is `completed` and the caller is an authorized
     organizer/admin for that club
   - selects every enrolment with `attendance_status = 'attended'`
   - skips anyone who already has a `certificates` row for this event
     (idempotency — safe to click twice)
   - generates a personalized PDF with `pdf-lib` (black-and-gold themed,
     student name, event name, club name, date, unique code, issue date,
     signature line)
   - uploads to the private `certificates` bucket at
     `<event_id>/<user_id>.pdf`
   - inserts the `certificates` row (the `guard_certificate_attendance`
     trigger is a second, independent check that the insert is legitimate)
5. `notify_certificate_issued()` trigger creates an in-app notification.
6. Student opens **My Certificates**, taps download → repository requests
   a 5-minute signed URL (`storage.createSignedUrl`) → opens/downloads.

## Certificate content

CampusPulse heading, "Certificate of Participation", student full name,
event name, organizing club, event date, unique certificate code, issue
date, and a signature line. (The spec's "verification QR code or URL" is
implemented as the certificate code being enterable on the public
`/verify-certificate` screen — a scannable QR containing that same
deep-link URL is a straightforward addition to `buildCertificatePdf()` if
wanted, but the current PDF only embeds the text code.)

## Rules enforced (and where)

| Rule | Enforced by |
|---|---|
| Only attended students | Edge Function query filter **and** `guard_certificate_attendance` DB trigger (defense in depth) |
| One per student per event | `unique (event_id, user_id)` constraint + explicit skip-if-exists check in the function |
| Repeated issue requests are idempotent | Same skip-if-exists check |
| Students can't alter certificate data | No client write policy on `certificates` at all |
| PDFs are private | `certificates` storage bucket has zero client-facing policies |
| Download uses short-lived signed URLs | `signedDownloadUrl()` in `SupabaseCertificateRepository`, 300-second TTL |
| "Certificate not issued yet" state | `MyCertificatesScreen` empty state when `myCertificates()` returns `[]` for a given event |

## Verification screen

`/verify-certificate?code=XXXX` (also reachable by manually entering a
code) shows only: student name, event name, organizer, event date, and a
valid/invalid indicator — no other student data, per spec section 19.
