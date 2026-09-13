-- CampusPulse: enrolments + favourites

create table enrolments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  qr_token text not null unique,
  enrolled_at timestamptz not null default now(),
  attendance_status text not null default 'registered'
    check (attendance_status in ('registered', 'attended', 'absent')),
  attended_at timestamptz,
  attendance_marked_by uuid references profiles (id),
  unique (event_id, user_id)
);

create index idx_enrolments_event on enrolments (event_id);
create index idx_enrolments_user on enrolments (user_id);
create index idx_enrolments_qr_token on enrolments (qr_token);

create table favourites (
  user_id uuid not null references profiles (id) on delete cascade,
  event_id uuid not null references events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create index idx_favourites_event on favourites (event_id);

-- ---------------------------------------------------------------------
-- enrol_in_event: the ONLY sanctioned way to create an enrolment.
-- Runs as SECURITY DEFINER so it can validate + insert atomically and
-- generate the QR token server-side (never client-supplied).
-- ---------------------------------------------------------------------
create or replace function enrol_in_event(target_event_id uuid)
returns enrolments
language plpgsql security definer set search_path = public as $$
declare
  v_event events%rowtype;
  v_enrolment enrolments%rowtype;
begin
  select * into v_event from events where id = target_event_id for update;

  if v_event.id is null then
    raise exception 'Event not found.';
  end if;
  if v_event.status <> 'published' then
    raise exception 'This event is not open for registration.';
  end if;
  if now() > v_event.registration_deadline then
    raise exception 'Registration for this event has closed.';
  end if;
  if now() > v_event.start_at then
    raise exception 'This event has already started.';
  end if;

  insert into enrolments (event_id, user_id, qr_token)
  values (target_event_id, auth.uid(), encode(gen_random_bytes(24), 'hex'))
  on conflict (event_id, user_id) do nothing
  returning * into v_enrolment;

  if v_enrolment.id is null then
    raise exception 'You are already enrolled in this event.';
  end if;

  return v_enrolment;
end;
$$;
