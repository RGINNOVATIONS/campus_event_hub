-- ============================================================
-- Rollback: 20260830000002_tight_profiles_attendee_rls_rollback.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Restore initial strict own-or-admin profiles SELECT policy.
-- ============================================================

begin;

drop policy if exists "profiles_select_own_admin_or_event_attendees" on public.profiles;
drop policy if exists "profiles_select_policy" on public.profiles;
drop policy if exists "profiles_select_organizer_attendees" on public.profiles;
drop policy if exists "profiles_select_own_or_admin" on public.profiles;

create policy "profiles_select_own_or_admin" on public.profiles for select
  using (id = auth.uid() or is_admin());

commit;
