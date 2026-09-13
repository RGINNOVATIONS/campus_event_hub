-- CampusPulse: attendance audit + protected marking function

create table attendance_audit (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events (id) on delete cascade,
  enrolment_id uuid references enrolments (id) on delete set null,
  scanned_by uuid not null references profiles (id),
  scanned_at timestamptz not null default now(),
  scan_result text not null,
  device_information text
);

create index idx_attendance_audit_event on attendance_audit (event_id);
create index idx_attendance_audit_enrolment on attendance_audit (enrolment_id);

-- ---------------------------------------------------------------------
-- mark_event_attendance: the ONLY sanctioned way to change
-- attendance_status. Students cannot call this in a way that marks
-- themselves attended — it requires the caller to be a verified
-- organizer of the event's club (or an admin), enforced here, not just
-- by RLS on the table.
--
-- Returns a text code the client maps via ScanResultMapper:
--   ok | already_checked_in | invalid_token | wrong_event | not_authorized
-- ---------------------------------------------------------------------
create or replace function mark_event_attendance(p_qr_token text, p_event_id uuid, p_device_information text default null)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_enrolment enrolments%rowtype;
  v_club_id uuid;
  v_result text;
begin
  select club_id into v_club_id from events where id = p_event_id;

  if v_club_id is null then
    v_result := 'wrong_event';
  elsif not (is_verified_organizer_for_club(v_club_id) or is_admin()) then
    v_result := 'not_authorized';
  else
    select * into v_enrolment from enrolments
      where qr_token = p_qr_token
      for update;

    if v_enrolment.id is null then
      v_result := 'invalid_token';
    elsif v_enrolment.event_id <> p_event_id then
      v_result := 'wrong_event';
    elsif v_enrolment.attendance_status = 'attended' then
      v_result := 'already_checked_in';
    else
      update enrolments
        set attendance_status = 'attended',
            attended_at = now(),
            attendance_marked_by = auth.uid()
        where id = v_enrolment.id;
      v_result := 'ok';
    end if;
  end if;

  insert into attendance_audit (event_id, enrolment_id, scanned_by, scan_result, device_information)
  values (p_event_id, v_enrolment.id, auth.uid(), v_result, p_device_information);

  return v_result;
end;
$$;
