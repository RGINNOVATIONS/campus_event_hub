-- CampusPulse: certificates
-- Issuance itself happens in the `issue-certificates` Edge Function using
-- the service_role key (never exposed to the client). This table only
-- stores metadata + the private storage path.

create table certificates (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  certificate_code text not null unique,
  pdf_path text not null,
  issued_by uuid not null references profiles (id),
  issued_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create index idx_certificates_user on certificates (user_id);
create index idx_certificates_code on certificates (certificate_code);

-- Belt-and-braces: even if something bypasses the Edge Function and tries
-- a raw insert, the DB itself refuses to create a certificate for anyone
-- whose attendance isn't 'attended'.
create or replace function guard_certificate_attendance()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from enrolments e
    where e.event_id = new.event_id
      and e.user_id = new.user_id
      and e.attendance_status = 'attended'
  ) then
    raise exception 'Certificates may only be issued to attended students.';
  end if;
  return new;
end;
$$;

create trigger trg_guard_certificate_attendance
  before insert on certificates
  for each row execute function guard_certificate_attendance();

-- Notify the student once their certificate exists.
create or replace function notify_certificate_issued()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_event_title text;
begin
  select title into v_event_title from events where id = new.event_id;
  insert into notifications (user_id, type, title, body, event_id)
  values (new.user_id, 'certificate_issued', 'Certificate ready',
          'Your certificate for ' || coalesce(v_event_title, 'the event') || ' is ready to download.', new.event_id);
  return new;
end;
$$;

create trigger trg_notify_certificate_issued
  after insert on certificates
  for each row execute function notify_certificate_issued();
