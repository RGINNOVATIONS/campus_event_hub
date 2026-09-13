-- CampusPulse: Fix event lifecycle RLS & Admin approval RPC
-- Migration: 20260814000001_fix_event_lifecycle_rls.sql

-- 1. Ensure events SELECT policy allows published events to be read by all authenticated/anon users,
-- pending_approval events to be read by admins & club organizers, and drafts by club organizers.
drop policy if exists "events_select" on events;
create policy "events_select" on events for select
  using (
    status = 'published'
    or is_admin()
    or is_verified_organizer_for_club(club_id)
  );

-- 2. Atomic, SECURITY DEFINER RPC function for Admin Event Approval.
-- Guarantees that even if client RLS policies vary, an authenticated administrator
-- can approve a pending event atomically with full server-side authorization enforcement.
create or replace function approve_event_by_admin(p_event_id uuid)
returns events
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  if not is_admin() then
    raise exception 'Only administrators may approve events.'
      using errcode = '42501';
  end if;

  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.'
      using errcode = 'P0002';
  end if;

  if v_event.status <> 'pending_approval' then
    raise exception 'Event is not in pending_approval state (current status: %).', v_event.status
      using errcode = 'P0001';
  end if;

  -- Automatically verify the event's club if pending, so student RLS permits reading club details
  update clubs
    set verification_status = 'verified',
        verified_by = auth.uid(),
        verified_at = now()
    where id = v_event.club_id and verification_status = 'pending';

  update events
    set status = 'published',
        approved_by = auth.uid(),
        approved_at = now(),
        published_at = now(),
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 3. Atomic, SECURITY DEFINER RPC function for Admin Event Rejection.
create or replace function reject_event_by_admin(p_event_id uuid, p_rejection_reason text)
returns events
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  if not is_admin() then
    raise exception 'Only administrators may reject events.'
      using errcode = '42501';
  end if;

  if p_rejection_reason is null or trim(p_rejection_reason) = '' then
    raise exception 'Rejection reason is required.'
      using errcode = 'P0001';
  end if;

  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.'
      using errcode = 'P0002';
  end if;

  update events
    set status = 'rejected',
        rejection_reason = trim(p_rejection_reason),
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 4. Atomic, SECURITY DEFINER RPC function for Organizer Submit for Approval.
create or replace function submit_event_for_approval(p_event_id uuid)
returns events
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
begin
  select * into v_event from events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.'
      using errcode = 'P0002';
  end if;

  if not is_verified_organizer_for_club(v_event.club_id) and not is_admin() then
    raise exception 'Not authorized to submit events for this club.'
      using errcode = '42501';
  end if;

  if v_event.status not in ('draft', 'rejected') then
    raise exception 'Only draft or rejected events can be submitted for approval (current status: %).', v_event.status
      using errcode = 'P0001';
  end if;

  update events
    set status = 'pending_approval',
        rejection_reason = null,
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;
