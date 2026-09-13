-- CampusPulse: events

create table events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs (id) on delete cascade,
  category_id uuid not null references categories (id),
  created_by uuid not null references profiles (id),
  title text not null,
  short_description text not null,
  full_description text not null,
  poster_path text,
  venue text not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  registration_deadline timestamptz not null,
  eligibility text not null default '',
  rules text not null default '',
  fee_text text,
  contact_name text not null,
  contact_email text not null,
  contact_phone text,
  status text not null default 'draft'
    check (status in ('draft', 'pending_approval', 'published', 'rejected', 'cancelled', 'completed')),
  rejection_reason text,
  approved_by uuid references profiles (id),
  approved_at timestamptz,
  published_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_event_dates check (end_at > start_at),
  constraint chk_registration_before_start check (registration_deadline <= start_at)
);

create index idx_events_status_start on events (status, start_at);
create index idx_events_club on events (club_id);
create index idx_events_category on events (category_id);

create trigger trg_events_updated_at
  before update on events
  for each row execute function set_updated_at();
