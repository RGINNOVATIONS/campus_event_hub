-- CampusPulse: Row-Level Security
-- Every table the Flutter client touches is covered. The client uses only
-- the anon/authenticated key — never service_role.

alter table allowed_email_domains enable row level security;
alter table profiles enable row level security;
alter table clubs enable row level security;
alter table club_members enable row level security;
alter table categories enable row level security;
alter table club_follows enable row level security;
alter table category_follows enable row level security;
alter table events enable row level security;
alter table enrolments enable row level security;
alter table favourites enable row level security;
alter table notifications enable row level security;
alter table device_tokens enable row level security;
alter table certificates enable row level security;
alter table attendance_audit enable row level security;

-- allowed_email_domains: public read (needed at registration, pre-auth
-- via anon key), writes restricted to admins.
create policy "domains_public_read" on allowed_email_domains for select using (true);
create policy "domains_admin_write" on allowed_email_domains for all
  using (is_admin()) with check (is_admin());

-- profiles: read own; admins read all. Update allowed on non-role fields
-- only (role changes are blocked by the protect_role_column trigger,
-- independent of this policy, so this is defense in depth).
create policy "profiles_select_own_or_admin" on profiles for select
  using (id = auth.uid() or is_admin());
create policy "profiles_update_own_or_admin" on profiles for update
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());
-- Inserts happen only via the handle_new_user() trigger (security definer),
-- so no client-facing insert policy is granted.

-- clubs: any authenticated user can read verified clubs; admins read all.
create policy "clubs_select_verified_or_admin" on clubs for select
  using (verification_status = 'verified' or is_admin() or
         exists (select 1 from club_members cm where cm.club_id = clubs.id and cm.user_id = auth.uid()));
create policy "clubs_admin_write" on clubs for all
  using (is_admin()) with check (is_admin());

-- club_members: members can see their own club roster; admins see all.
create policy "club_members_select" on club_members for select
  using (user_id = auth.uid() or is_admin() or is_verified_organizer_for_club(club_id));
create policy "club_members_admin_write" on club_members for all
  using (is_admin()) with check (is_admin());

-- categories: public read, admin write.
create policy "categories_public_read" on categories for select using (true);
create policy "categories_admin_write" on categories for all
  using (is_admin()) with check (is_admin());

-- club_follows / category_follows: users manage only their own rows.
create policy "club_follows_own" on club_follows for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "category_follows_own" on category_follows for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- events: students/public see only published events. Organizers see their
-- own club's events regardless of status. Admins see everything.
create policy "events_select" on events for select
  using (
    status = 'published'
    or is_admin()
    or is_verified_organizer_for_club(club_id)
  );

-- Organizers may create/update drafts and pending-approval events for
-- their own verified club, but may NOT set status to 'published'
-- themselves (that transition only happens via the admin approval
-- policy below) and may not touch approval/publish metadata columns.
create policy "events_insert_organizer" on events for insert
  with check (
    is_verified_organizer_for_club(club_id)
    and status in ('draft', 'pending_approval')
    and created_by = auth.uid()
  );

create policy "events_update_organizer" on events for update
  using (is_verified_organizer_for_club(club_id) and status in ('draft', 'pending_approval', 'rejected'))
  with check (is_verified_organizer_for_club(club_id) and status in ('draft', 'pending_approval'));

create policy "events_admin_all" on events for all
  using (is_admin()) with check (is_admin());

-- enrolments: students see + create only their own. Organizers see
-- enrolments for their own club's events (read-only — attendance changes
-- must go through mark_event_attendance()).
create policy "enrolments_select" on enrolments for select
  using (
    user_id = auth.uid()
    or is_admin()
    or exists (select 1 from events e where e.id = enrolments.event_id and is_verified_organizer_for_club(e.club_id))
  );
-- No direct insert policy: creation only via enrol_in_event() (SECURITY DEFINER).
-- No update policy: attendance changes only via mark_event_attendance().

-- favourites: fully owned by the student.
create policy "favourites_own" on favourites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- notifications: users see + update (mark read) only their own.
create policy "notifications_own_select" on notifications for select
  using (user_id = auth.uid());
create policy "notifications_own_update" on notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- device_tokens: users manage only their own tokens.
create policy "device_tokens_own" on device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- certificates: students read only their own; organizers of the event's
-- club may read for verification purposes; admins read all. Inserts only
-- via the Edge Function using service_role (bypasses RLS by design), so
-- no client insert policy is granted.
create policy "certificates_select" on certificates for select
  using (
    user_id = auth.uid()
    or is_admin()
    or exists (select 1 from events e where e.id = certificates.event_id and is_verified_organizer_for_club(e.club_id))
  );

-- attendance_audit: organizers/admins of the relevant club may read;
-- no client write policy (only mark_event_attendance() writes, as
-- SECURITY DEFINER).
create policy "attendance_audit_select" on attendance_audit for select
  using (
    is_admin()
    or exists (select 1 from events e where e.id = attendance_audit.event_id and is_verified_organizer_for_club(e.club_id))
  );
