# Notifications

Two layers: **in-app** (always works, backed by the `notifications`
table) and **push** (FCM, best-effort — requires a registered device
token and a deployed `fcm-send` function).

## Triggers → in-app rows

All fan-out happens server-side via Postgres triggers on `events` and
`certificates` (see `docs/DATABASE.md`), not client-side:

| Event | Trigger | Recipients |
|---|---|---|
| Event published | `notify_event_published()` | followers of the club **or** the category, de-duplicated |
| Event approved | `notify_event_decision()` | the organizer who created it |
| Event rejected | `notify_event_decision()` | the organizer who created it |
| Event cancelled | `notify_event_decision()` | every enrolled student |
| 24h before start | `event-reminders` Edge Function (scheduled) | every enrolled student, idempotent |
| Certificate issued | `notify_certificate_issued()` | the student |

## Deduplication

When a student follows both the event's club and its category, the
published-event trigger uses `UNION` (not `UNION ALL`) across the two
follower sets before inserting, so they get exactly one row. The same
logic is unit-tested client-side as `NotificationDedup` (used nowhere in
the client today since the server already dedupes, but kept because the
spec calls it out as independently testable business logic).

## Push delivery (FCM HTTP v1)

`fcm-send` (Deno Edge Function) does a JWT-bearer OAuth2 exchange against
the Firebase service-account credentials (a secret, never in the client)
to get an access token, then POSTs to
`https://fcm.googleapis.com/v1/projects/<project>/messages:send` for each
of the user's `device_tokens` rows. It's designed to be called after any
insert into `notifications` — wiring a Postgres `pg_net` webhook or
calling it directly from `event-reminders`/other functions is the
integration point (not wired to a generic "on every insert" trigger in
this build, to avoid an extra network call on paths that don't need push
urgency — call it explicitly where it matters).

## Client-side pieces

- **Device token registration**: `firebase_messaging` obtains a token;
  it should be upserted into `device_tokens` on login and refreshed on
  the `onTokenRefresh` stream. (Interface stubbed under
  `lib/core/services/` — not device-tested in this build sandbox, see
  `TASKS.md`.)
- **Foreground display**: `flutter_local_notifications` shows a system
  notification when a push arrives while the app is open.
- **Background navigation**: tapping a push should deep-link via
  `go_router` to `/event/:id` using the `event_id` payload field set by
  both `fcm-send` and the in-app notification row.
- **In-app centre**: `NotificationCentreScreen` — list, unread badge
  (`unreadNotificationCountProvider`), mark one read, mark all read.
- **Permission denial**: if the OS notification permission is denied, the
  app should keep working with in-app notifications only — this is a
  graceful-degradation path noted in code comments but not separately
  exercised by tests in this build.

## Idempotency

`event-reminders` checks for an existing `type = 'event_reminder_24h'`
row for the same `(user_id, event_id)` before inserting, so re-running the
scheduled job on overlapping windows never double-notifies.
