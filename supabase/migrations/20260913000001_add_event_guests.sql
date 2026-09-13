-- ============================================================
-- Migration: 20260913000001_add_event_guests.sql
-- Purpose: Add structured guest/speaker details to events:
--          1. Add guests jsonb column to public.events
--          2. Drop old 16-param update_event_by_organizer to ensure single overload in pg_proc
--          3. Recreate update_event_by_organizer with trailing p_guests jsonb default null
--          4. Explicitly grant execute on the new function signature to authenticated role
-- ============================================================

begin;

-- 1. Add guests column if not exists (non-null JSONB array, default empty array)
alter table public.events
  add column if not exists guests jsonb not null default '[]'::jsonb;

-- 2. Drop 16-parameter version of update_event_by_organizer to ensure clean single-overload in pg_proc
drop function if exists public.update_event_by_organizer(
  uuid, text, text, text, uuid, text, timestamptz, timestamptz, timestamptz,
  text, text, text, text, text, text, text
);

-- 3. Create or replace update_event_by_organizer with p_guests parameter
create or replace function public.update_event_by_organizer(
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
  p_contact_phone text default null,
  p_guests jsonb default null
)
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

  if p_end_at <= p_start_at then
    raise exception 'End time must be after start time.' using errcode = 'P0001';
  end if;

  if p_registration_deadline > p_start_at then
    raise exception 'Registration deadline must be before or at event start time.' using errcode = 'P0001';
  end if;

  update public.events
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
        guests = coalesce(p_guests, v_event.guests, '[]'::jsonb),
        updated_at = now()
    where id = p_event_id
    returning * into v_event;

  return v_event;
end;
$$;

-- 4. Explicitly grant execute on the 17-parameter function to authenticated
grant execute on function public.update_event_by_organizer(
  uuid, text, text, text, uuid, text, timestamptz, timestamptz, timestamptz,
  text, text, text, text, text, text, text, jsonb
) to authenticated;

commit;
