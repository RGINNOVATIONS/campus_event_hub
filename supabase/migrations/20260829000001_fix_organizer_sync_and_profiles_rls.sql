-- CampusPulse: Fix Organizer Data Synchronization, Profile Visibility, and Postponed Event Registration
-- Migration: 20260829000001_fix_organizer_sync_and_profiles_rls.sql

-- 1. Update enrol_in_event() RPC function to allow registration for published AND postponed events.
create or replace function enrol_in_event(target_event_id uuid)
returns enrolments
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
  v_enrolment enrolments%rowtype;
begin
  select * into v_event from events where id = target_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if v_event.status not in ('published', 'postponed') then
    raise exception 'This event is not open for registration.' using errcode = 'P0001';
  end if;

  if now() > v_event.registration_deadline then
    raise exception 'Registration for this event has closed.' using errcode = 'P0001';
  end if;

  if now() > v_event.start_at then
    raise exception 'This event has already started.' using errcode = 'P0001';
  end if;

  insert into enrolments (event_id, user_id, qr_token)
  values (target_event_id, auth.uid(), encode(gen_random_bytes(24), 'hex'))
  on conflict (event_id, user_id) do nothing
  returning * into v_enrolment;

  if v_enrolment.id is null then
    raise exception 'You are already enrolled in this event.' using errcode = '23505';
  end if;

  return v_enrolment;
end;
$$;

-- 2. Update profiles SELECT policy so organizers can read profiles of students who are registered
-- for their verified club's events, and fellow club members, while preserving strict authorization.
drop policy if exists "profiles_select_own_or_admin" on profiles;
drop policy if exists "profiles_select_organizer_attendees" on profiles;

create policy "profiles_select_policy" on profiles for select
  using (
    id = auth.uid()
    or is_admin()
    or exists (
      select 1 from enrolments en
      join events ev on ev.id = en.event_id
      where en.user_id = profiles.id
        and is_verified_organizer_for_club(ev.club_id)
    )
    or exists (
      select 1 from club_members cm
      where cm.user_id = profiles.id
        and is_verified_organizer_for_club(cm.club_id)
    )
  );

-- 3. Ensure enrolments SELECT policy allows organizers to view enrolments for their verified club's events.
drop policy if exists "enrolments_select" on enrolments;
create policy "enrolments_select" on enrolments for select
  using (
    user_id = auth.uid()
    or is_admin()
    or exists (
      select 1 from events e
      where e.id = enrolments.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  );
