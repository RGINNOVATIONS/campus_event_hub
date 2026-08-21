# Security

The Flutter client only ever holds the Supabase **anon** key and the
Firebase **client** config. No `service_role` key, no Firebase
service-account JSON, ships in the app — both are Edge Function secrets
only (`supabase secrets set ...`).

## Principle

> Hiding a button in the UI is not authorization.

Every sensitive action has a server-side check, independent of what the
Flutter app shows:

| Action | Client-side check (UX only) | Server-side enforcement |
|---|---|---|
| Change own role | n/a — no UI for it | `protect_role_column()` trigger rejects the UPDATE unless caller is already admin |
| Create an enrolment | Enroll button disabled when closed | `enrol_in_event()` re-validates status/deadline/start; no direct INSERT policy exists on `enrolments` |
| Mark attendance | Scan screen only shown to organizer/admin | `mark_event_attendance()` checks `is_verified_organizer_for_club()`/`is_admin()` itself; no UPDATE policy exists on `enrolments` |
| Publish an event | Organizer form can't set status to published | RLS policy `events_update_organizer` only allows organizers to move an event to `draft`/`pending_approval`; only the admin-only `events_admin_all` policy can set `published` |
| Issue a certificate | Button only shown post-completion | `guard_certificate_attendance()` trigger rejects any insert for a non-`attended` enrolment; the Edge Function itself checks the event is `completed` and the caller is an authorized organizer/admin before doing anything |
| Read someone else's certificate | n/a | RLS `certificates_select` restricts to the owner, the event's organizers, or admins; the storage bucket has **no** client read policy at all — a signed URL is mandatory |

## Row-Level Security summary

RLS is enabled on every table in `20260801000008_rls_policies.sql`.
Broad strokes:

- **profiles** — read/update own row (role changes blocked by trigger,
  not just policy); admins read/update all.
- **clubs / categories** — public read of verified/active rows; write
  restricted to admins (or, for clubs, also visible to their own
  members).
- **events** — public read only for `published`; organizers additionally
  see their own club's events at any status; admins see everything.
  Organizers can INSERT/UPDATE only into `draft`/`pending_approval`
  states for their own verified club.
- **enrolments / favourites / follows / notifications / device_tokens** —
  owned rows only, full CRUD for the owner, nothing for anyone else
  (organizers get read-only access to enrolments for their own events).
- **certificates / attendance_audit** — read-only for the owner (or
  scoped organizer/admin); no client write policy — the Edge Function's
  `service_role` client bypasses RLS entirely, which is the only path in.

## Storage policies

- `event-posters` (private): verified organizers upload/replace under
  their own `club_id/...` path; any authenticated user can read (needed
  for organizer preview of drafts, not just published posters — access to
  the *event row* is what actually gates draft visibility).
- `club-logos` (private): verified organizers/admins upload; authenticated
  read.
- `certificates` (private): **no client policy at all**. Only the
  `issue-certificates` Edge Function (using `service_role`) can write.
  Students obtain a 5-minute signed URL via
  `storage.createSignedUrl()`, never a direct object read.

## College-email domain enforcement

`allowed_email_domains` is a real table, publicly readable (needed
pre-auth, at registration time), admin-writable. Nothing in the codebase
hard-codes an institution's domain — see README section 6.3 for adding
your real domain(s) during setup.

**The enforcement boundary is server-side, not the Flutter form.**
`CollegeEmailValidator` in the registration screen is a fast client-side
pre-check only — like every other client-side check in this app, it
exists for UX, not security. The actual boundary is inside
`handle_new_user()` (see
`supabase/migrations/20260802000001_enforce_email_domain_on_signup.sql`):
it looks up the signing-up email's domain against `allowed_email_domains`
and raises an exception if it isn't there, which rolls back the entire
`auth.users` insert — so a disallowed-domain `signUp()` call fails
outright, whether it came from the app or a direct API call. This closes
a real gap found on audit: the original trigger never checked the
domain at all. If `allowed_email_domains` is empty, every signup is
rejected (fail closed) — insert your real domain before enabling
registration. See `supabase/verification_queries.sql` query #9 to verify
this against a live project.

## Bootstrapping the first administrator

There is intentionally **no in-app "become admin" flow** — that would be
an unauthenticated privilege-escalation path. The first admin is promoted
directly via SQL by whoever holds the Supabase project's database
credentials (see README section 6.5). Every admin after that is created
by an existing admin through normal role management.
