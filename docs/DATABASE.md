# Database

All tables live in `supabase/migrations/`, applied in filename (timestamp)
order. UUID primary keys throughout, `pgcrypto`'s `gen_random_uuid()`.

## Entity overview

```
auth.users (Supabase-managed)
  └── profiles (1:1, role: student|organizer|admin)

allowed_email_domains        — configurable college-domain allowlist

clubs
  ├── club_members (club ↔ profiles, member_role: organizer|lead)
  ├── club_follows (profiles ↔ clubs)
  └── events
        ├── enrolments (profiles ↔ events, qr_token, attendance_status)
        │     └── attendance_audit (every scan attempt, success or not)
        ├── favourites (profiles ↔ events)
        ├── certificates (profiles ↔ events, one per pair)
        └── notifications (event_id nullable — some notifications aren't event-scoped)

categories
  └── category_follows (profiles ↔ categories)

device_tokens (profiles → FCM tokens, one row per device)
```

## Status enums

- `clubs.verification_status`: `pending | verified | rejected | suspended`
- `events.status`: `draft | pending_approval | published | rejected | cancelled | completed`
- `enrolments.attendance_status`: `registered | attended | absent`

## Constraints worth knowing about

- `events`: `end_at > start_at`, `registration_deadline <= start_at`
  (`chk_event_dates`, `chk_registration_before_start`)
- `enrolments`: unique `(event_id, user_id)` and unique `qr_token`
- `favourites` / `club_follows` / `category_follows`: composite primary
  keys double as the uniqueness constraint
- `certificates`: unique `(event_id, user_id)` and unique
  `certificate_code`; a `before insert` trigger
  (`guard_certificate_attendance`) rejects any insert where the target
  enrolment isn't `attended`, independent of whatever called the insert

## Indexes

`idx_events_status_start (status, start_at)` is the one the student feed
query relies on (`WHERE status = 'published' ORDER BY start_at`). Others:
`idx_events_club`, `idx_events_category`, `idx_enrolments_event`,
`idx_enrolments_user`, `idx_favourites_event`,
`idx_notifications_user_unread (user_id, is_read)`,
`idx_certificates_user`, `idx_attendance_audit_event`.

## `updated_at`

A single generic trigger function `set_updated_at()` is attached to every
table that has the column (`profiles`, `clubs`, `events`).

## Server-side functions (all `SECURITY DEFINER`, `search_path = public`)

- `is_admin()` — used throughout RLS policies
- `is_verified_organizer_for_club(club_id)` — same
- `enrol_in_event(event_id)` — the only way an enrolment is created;
  validates status/deadline/start atomically, generates the QR token
- `mark_event_attendance(qr_token, event_id, device_info)` — the only way
  attendance changes; returns a text result code (`ok`,
  `already_checked_in`, `invalid_token`, `wrong_event`, `not_authorized`)
  and always logs to `attendance_audit`, success or failure
- `protect_role_column()` — trigger; blocks any UPDATE that changes
  `profiles.role` unless the caller is already an admin
- `handle_new_user()` / `handle_user_email_verified()` — triggers on
  `auth.users` that create/sync the `profiles` row
- `notify_event_published()` / `notify_event_decision()` — triggers on
  `events` that fan out `notifications` rows (with de-duplication across
  club-follow + category-follow recipients)
- `guard_certificate_attendance()` / `notify_certificate_issued()` —
  triggers on `certificates`

See `docs/SECURITY.md` for how these interact with RLS.
