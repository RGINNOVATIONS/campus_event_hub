-- ============================================================
-- Migration: 20260830000002_tight_profiles_attendee_rls.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Allow verified organizers to read profile fields
--          strictly for students enrolled in their club's events.
-- ============================================================

begin;

-- 1. Drop existing / legacy select policies
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
drop policy if exists "profiles_select_organizer_attendees" on public.profiles;
drop policy if exists "profiles_select_policy" on public.profiles;
drop policy if exists "profiles_select_own_admin_or_event_attendees" on public.profiles;

-- 2. Create the tight, event-attendee scoped select policy
create policy "profiles_select_own_admin_or_event_attendees" on public.profiles for select
  using (
    id = auth.uid()
    or is_admin()
    or exists (
      select 1 from public.enrolments en
      join public.events ev on ev.id = en.event_id
      where en.user_id = profiles.id
        and is_verified_organizer_for_club(ev.club_id)
    )
  );

commit;
