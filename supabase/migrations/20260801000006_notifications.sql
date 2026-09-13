-- CampusPulse: notifications + device tokens

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  event_id uuid references events (id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user_unread on notifications (user_id, is_read);
create index idx_notifications_event on notifications (event_id);

create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  fcm_token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  last_seen_at timestamptz not null default now(),
  unique (fcm_token)
);

create index idx_device_tokens_user on device_tokens (user_id);

-- ---------------------------------------------------------------------
-- notify_event_published: fires when an event flips to 'published'.
-- Dedupes recipients who follow both the club and the category so each
-- user gets exactly one row (mirrors NotificationDedup in the client).
-- ---------------------------------------------------------------------
create or replace function notify_event_published()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'published' and (old.status is distinct from 'published') then
    insert into notifications (user_id, type, title, body, event_id)
    select distinct recipient, 'event_published', 'New event: ' || new.title,
           'A club or category you follow just published a new event.', new.id
    from (
      select cf.user_id as recipient from club_follows cf where cf.club_id = new.club_id
      union
      select cf2.user_id as recipient from category_follows cf2 where cf2.category_id = new.category_id
    ) recipients(recipient);
  end if;
  return new;
end;
$$;

create trigger trg_notify_event_published
  after update on events
  for each row execute function notify_event_published();

-- Notifies the organizer who created the event when it is approved or rejected.
create or replace function notify_event_decision()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'published' and old.status = 'pending_approval' then
    insert into notifications (user_id, type, title, body, event_id)
    values (new.created_by, 'event_approved', 'Event approved', new.title || ' has been approved and published.', new.id);
  elsif new.status = 'rejected' and old.status = 'pending_approval' then
    insert into notifications (user_id, type, title, body, event_id)
    values (new.created_by, 'event_rejected', 'Event needs changes', new.title || ' was rejected: ' || coalesce(new.rejection_reason, ''), new.id);
  elsif new.status = 'cancelled' and old.status <> 'cancelled' then
    insert into notifications (user_id, type, title, body, event_id)
    select e.user_id, 'event_cancelled', 'Event cancelled', new.title || ' has been cancelled.', new.id
    from enrolments e where e.event_id = new.id;
  end if;
  return new;
end;
$$;

create trigger trg_notify_event_decision
  after update on events
  for each row execute function notify_event_decision();
