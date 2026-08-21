# Deployment

End-to-end checklist for taking CampusPulse from this repo to a live
Supabase + Firebase backend and installable builds. See `README.md` for
the detailed version of each step; this is the ordered checklist.

## 1. Supabase project
- [ ] Create project, note URL + anon key
- [ ] `supabase link` + `supabase db push` (applies all of
      `supabase/migrations/` in order)
- [ ] Insert your real domain(s) into `allowed_email_domains`
- [ ] Confirm the three storage buckets exist with the right
      size-limit/MIME settings (`event-posters`, `club-logos`,
      `certificates`)
- [ ] Register + verify one account, then promote it to `admin` via SQL
      (the only "become admin" path — see `docs/SECURITY.md`)
- [ ] As that admin, verify your real clubs and add organizer
      `club_members` rows

## 2. Firebase project
- [ ] Create project, enable Cloud Messaging
- [ ] Add client config values to `.env`
- [ ] Generate a service-account key; store it only as a Supabase secret
      (`FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_PROJECT_ID`) — never in
      the repo or the client

## 3. Edge Functions
- [ ] `supabase functions deploy fcm-send`
- [ ] `supabase functions deploy issue-certificates`
- [ ] `supabase functions deploy event-reminders`
- [ ] Schedule `event-reminders` with `pg_cron` (see README section 10)

## 4. App config
- [ ] `.env` with real `SUPABASE_URL` / `SUPABASE_ANON_KEY` /
      `FIREBASE_*` values, `APP_DEMO_MODE=false`
- [ ] `flutter create .` to generate platform folders (not run in the
      build sandbox — see README top note)
- [ ] Add `google-services.json` (Android) / `GoogleService-Info.plist`
      (iOS) / web Firebase config per FlutterFire docs
- [ ] `flutter pub get`

## 5. Verify before shipping
- [ ] `dart format .`
- [ ] `flutter analyze` — zero issues in application code
- [ ] `flutter test` — all unit + widget tests pass
- [ ] `flutter build apk --release` (or `--debug` first)
- [ ] `flutter build web`
- [ ] Manually walk all three role flows once against the live backend:
      register → verify → enrol → get QR → (as organizer) scan → mark
      completed → issue certificates → (as student) download certificate
- [ ] Confirm RLS by trying (and failing) to do something out-of-role
      directly against the REST API with a student's JWT — e.g. attempt
      to mark your own attendance, or read another student's certificate.
      `supabase/verification_queries.sql` has 10 documented queries
      covering the critical cases (role change, self-attendance, cross-
      club editing, certificate insertion, domain-bypass signup, etc.) —
      run through all of them, not just one.

## 6. Ongoing
- Rotate the Firebase service-account key periodically; update the
  Supabase secret, no client changes needed
- Review `attendance_audit` occasionally for repeated `not_authorized` or
  `invalid_token` results, which can indicate stale/shared QR passes
