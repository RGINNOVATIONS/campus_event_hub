# Acceptance Testing (manual)

Run these against demo mode first (no backend needed), then repeat
against a live Supabase/Firebase setup before shipping. Each test states
preconditions, actions, and the expected result.

## Live QA credentials

The live integration test keeps the Admin account as `admin@nmims.edu` but
does not store its password in source control or `qa_credentials.json`.
Supply the existing password through the local `ADMIN_QA_PASSWORD`
environment variable, then create the ignored Dart defines file and run the
test:

```powershell
@{ ADMIN_QA_PASSWORD = $env:ADMIN_QA_PASSWORD } |
  ConvertTo-Json | Set-Content .qa_defines.json
flutter test integration_test/qa_audit_test.dart -d emulator-5554 `
  --dart-define-from-file=.qa_defines.json
```

The password is never printed by the test. Delete `.qa_defines.json` after
the run if it is no longer needed; `.gitignore` excludes it.

## Current verification status

The current session executed the relevant verification checks and recorded the actual results:

- `flutter test test/unit/event_calendar_test.dart` -> passed: `00:01 +1: All tests passed!`
- `flutter analyze` -> no analyzer errors; a small set of `info` findings remains, but there are no compile blockers from the app code.
- `flutter build apk --debug` -> still fails before app compilation due to the Java toolchain: Gradle/Kotlin is being launched under Java 25.0.2, which is not compatible with the active Android build stack in this environment.
- The calendar feature is implemented at the app layer and verified by the focused regression, but the Android debug build remains blocked on the JDK selection rather than the app itself.

## Student

### Register / login
- **Precondition**: app freshly launched, demo mode on (or a live backend
  with `allowed_email_domains` configured).
- **Action**: tap "Don't have an account? Register", fill all fields with
  a college-domain email, accept terms, submit.
- **Expected**: account created; in live mode, a verification-required
  screen appears; in demo mode, you land signed in as a new unverified
  student.

### Login with demo chips
- **Action**: on the login screen, tap the "Student" demo chip, then Sign in.
- **Expected**: signed in as Aisha Sharma, redirected to the Home feed.

### View and filter events
- **Precondition**: signed in as student.
- **Action**: on Home, tap a category chip; then tap "All"; then tap "Following".
- **Expected**: the grid updates each time; "Following" shows only events
  whose club or category you follow; chips stay visible even if a filter
  produces zero results.

### Follow a club / category
- **Action**: open an event, tap the club name, tap "Follow" on the club
  details screen. Then go to Profile → Notification Preferences and
  toggle a category switch on.
- **Expected**: button flips to "Following" immediately; toggling the
  category switch reflects instantly; both persist if you navigate away
  and back within the session.

### Favourite an event
- **Action**: tap the heart on an event card or the "Favourite" button on
  event details.
- **Expected**: heart fills immediately (optimistic); event appears on
  the Favourites tab; tapping again removes it.

### Enrol
- **Precondition**: an upcoming published event, registration still open.
- **Action**: open event details, tap "Enroll".
- **Expected**: button becomes "View QR"; event appears on My Events.

### View QR
- **Action**: tap "View QR" (from event details or My Events).
- **Expected**: QR code renders; encodes only an opaque token, not your
  name/ID (visually — the code is not human-readable data).

### Receive a notification
- **Precondition**: (demo) seeded notifications exist; (live) an admin
  approves an event for a club/category you follow.
- **Action**: tap the bell icon on Home.
- **Expected**: unread badge count matches unread notifications; tapping
  a notification marks it read and deep-links to its event if it has one.

### View / download a certificate
- **Precondition**: an event you attended has been completed and
  certificates issued.
- **Action**: go to My Certificates, tap the download icon.
- **Expected**: (demo) a confirmation snackbar appears; (live) a signed
  URL opens/downloads the PDF. If not yet issued, the screen shows
  "Certificate not issued yet." instead of an empty list.

## Organizer

### Create event
- **Action**: from the organizer Dashboard, tap "Create Event", fill all
  required fields with valid dates (start in the future, end after start,
  deadline before start), tap "Save as Draft".
- **Expected**: event appears in My Events with status "draft".

### Upload poster
- **Action**: in the create/edit form, use the poster field (where wired
  to `image_picker`/`file_picker` against Supabase Storage in production)
  to select an image.
- **Expected**: preview shows; file rejected if not JPG/PNG/WebP or over
  5MB (enforced server-side by the storage bucket policy either way).

### Submit for approval
- **Action**: tap "Submit for Approval" on a draft.
- **Expected**: status becomes "Pending approval"; event disappears from
  the public student feed until an admin approves it.

### Rejection and resubmit
- **Precondition**: an admin has rejected one of your events with a reason.
- **Action**: open it in My Events, read the reason, tap "Edit & Resubmit".
- **Expected**: rejection reason is visible; form pre-fills; resubmitting
  moves it back to "Pending approval".

### View registrations
- **Action**: open a published event → its management screen.
- **Expected**: registrant list with names and attendance status.

### Scan QR / duplicate scan
- **Precondition**: a student is enrolled in your event.
- **Action**: select the event on the Scan screen, scan (or manually
  enter) their QR token; then scan the same token again.
- **Expected**: first scan shows a green "Checked in" banner; second scan
  shows a red "Already checked in" banner, not a silent success.

### Complete event and issue certificates
- **Action**: mark the event completed (confirm dialog), then "Issue Certificates".
- **Expected**: only attended students are counted/credited; a success
  message states how many were issued.

## Administrator

### Verify club / organizer
- **Action**: open Clubs, find a "pending" club, tap the check icon.
- **Expected**: club status becomes "verified"; it now appears to
  students on event details / club search.

### Approve event
- **Action**: open Pending Events, tap "Approve" on one.
- **Expected**: it disappears from Pending; appears in the student feed
  and the official calendar; the organizer gets an "approved" notification.

### Reject event
- **Action**: tap "Reject", enter a reason, confirm.
- **Expected**: rejection requires non-empty text (dialog won't submit
  empty); organizer receives the reason via notification and can resubmit.

### Cancel event
- **Action**: open the Calendar, tap the cancel icon on a published event,
  confirm in the dialog.
- **Expected**: event status becomes "cancelled"; every enrolled student
  gets a cancellation notification; it no longer appears in the public feed.

### Verify official calendar
- **Action**: open the Calendar tab.
- **Expected**: only published events appear, sorted by date.
