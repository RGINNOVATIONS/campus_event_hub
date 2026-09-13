-- ============================================================
-- Migration: 20260830000004_complete_event_by_organizer.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Add atomic SECURITY DEFINER RPC to allow verified organizers
--          to mark published or postponed events completed.
-- Safety:
--   - Idempotent, transaction-wrapped.
--   - Enforces is_verified_organizer_for_club(v_event.club_id) or is_admin().
--   - Only allows transition from ('published', 'postponed') to 'completed'.
--   - Does NOT touch or loosen any table RLS policies.
-- ============================================================

begin;

-- 1. Ensure completed_at column exists
alter table public.events add column if not exists completed_at timestamptz;

-- 2. SECURITY DEFINER RPC: complete_event_by_organizer
create or replace function public.complete_event_by_organizer(p_event_id uuid)
returns public.events
language plpgsql security definer set search_path = public as $$
declare
  v_event public.events%rowtype;
begin
  select * into v_event from public.events where id = p_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if not (is_verified_organizer_for_club(v_event.club_id) or is_admin()) then
    raise exception 'Not authorized to manage events for this club.' using errcode = '42501';
  end if;

  if v_event.status not in ('published', 'postponed') then
    raise exception 'Only published or postponed events can be marked completed (current status: %).', v_event.status
      using errcode = 'P0001';
  end if;

  update public.events
    set status = 'completed',
        completed_at = now(),
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 3. Explicit Grant
grant execute on function public.complete_event_by_organizer(uuid) to authenticated;

commit;
