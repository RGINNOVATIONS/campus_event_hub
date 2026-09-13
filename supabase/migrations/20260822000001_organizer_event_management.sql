-- CampusPulse: Organizer Event Management (Postponement, Safe Edit, Delete)
-- Migration: 20260822000001_organizer_event_management.sql

-- 1. Add postponement_reason column if not exists
alter table events add column if not exists postponement_reason text;

-- 2. Ensure status check constraint includes 'postponed'
do $$
begin
  -- Drop existing inline or named check constraint on status
  alter table events drop constraint if exists events_status_check;
  alter table events drop constraint if exists events_status_check1;
  alter table events drop constraint if exists chk_event_status;
exception when others then null;
end $$;

alter table events add constraint chk_event_status
  check (status in ('draft', 'pending_approval', 'published', 'rejected', 'cancelled', 'completed', 'postponed'));

-- 3. Update events SELECT policy so students/public see published & postponed events
drop policy if exists "events_select" on events;
create policy "events_select" on events for select
  using (
    status in ('published', 'postponed')
    or is_admin()
    or is_verified_organizer_for_club(club_id)
  );

-- 4. Update events UPDATE policy for verified organizers
drop policy if exists "events_update_organizer" on events;
create policy "events_update_organizer" on events for update
  using (is_verified_organizer_for_club(club_id) or is_admin())
  with check (is_verified_organizer_for_club(club_id) or is_admin());

-- 5. Update events DELETE policy for verified organizers
drop policy if exists "events_delete_organizer" on events;
create policy "events_delete_organizer" on events for delete
  using (is_verified_organizer_for_club(club_id) or is_admin());

-- 6. SECURITY DEFINER RPC: postpone_event_by_organizer
create or replace function postpone_event_by_organizer(
  p_event_id uuid,
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_registration_deadline timestamptz,
  p_postponement_reason text
)
returns events
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if not (is_verified_organizer_for_club(v_event.club_id) or is_admin()) then
    raise exception 'Not authorized to manage events for this club.' using errcode = '42501';
  end if;

  if p_end_at <= p_start_at then
    raise exception 'End time must be after start time.' using errcode = 'P0001';
  end if;

  if p_registration_deadline > p_start_at then
    raise exception 'Registration deadline must be before or at event start time.' using errcode = 'P0001';
  end if;

  if p_postponement_reason is null or trim(p_postponement_reason) = '' then
    raise exception 'Postponement reason is required.' using errcode = 'P0001';
  end if;

  update events
    set start_at = p_start_at,
        end_at = p_end_at,
        registration_deadline = p_registration_deadline,
        postponement_reason = trim(p_postponement_reason),
        status = 'postponed',
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 7. SECURITY DEFINER RPC: update_event_by_organizer
create or replace function update_event_by_organizer(
  p_event_id uuid,
  p_title text,
  p_short_description text,
  p_full_description text,
  p_category_id uuid,
  p_venue text,
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_registration_deadline timestamptz,
  p_poster_path text default null,
  p_eligibility text default '',
  p_rules text default '',
  p_fee_text text default null,
  p_contact_name text default '',
  p_contact_email text default '',
  p_contact_phone text default null
)
returns events
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if not (is_verified_organizer_for_club(v_event.club_id) or is_admin()) then
    raise exception 'Not authorized to manage events for this club.' using errcode = '42501';
  end if;

  if p_end_at <= p_start_at then
    raise exception 'End time must be after start time.' using errcode = 'P0001';
  end if;

  if p_registration_deadline > p_start_at then
    raise exception 'Registration deadline must be before or at event start time.' using errcode = 'P0001';
  end if;

  update events
    set title = p_title,
        short_description = p_short_description,
        full_description = p_full_description,
        category_id = p_category_id,
        venue = p_venue,
        start_at = p_start_at,
        end_at = p_end_at,
        registration_deadline = p_registration_deadline,
        poster_path = coalesce(p_poster_path, v_event.poster_path),
        eligibility = coalesce(p_eligibility, v_event.eligibility),
        rules = coalesce(p_rules, v_event.rules),
        fee_text = p_fee_text,
        contact_name = p_contact_name,
        contact_email = p_contact_email,
        contact_phone = p_contact_phone,
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 8. SECURITY DEFINER RPC: delete_event_by_organizer
create or replace function delete_event_by_organizer(p_event_id uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if not (is_verified_organizer_for_club(v_event.club_id) or is_admin()) then
    raise exception 'Not authorized to delete events for this club.' using errcode = '42501';
  end if;

  delete from events where id = p_event_id;
  return true;
end;
$$;
