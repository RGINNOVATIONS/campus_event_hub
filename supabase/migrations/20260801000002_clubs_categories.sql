-- CampusPulse: clubs, membership, categories, follows

create table clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  logo_path text,
  contact_email text not null,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  verified_at timestamptz,
  verified_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_clubs_status on clubs (verification_status);

create trigger trg_clubs_updated_at
  before update on clubs
  for each row execute function set_updated_at();

create table club_members (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  member_role text not null default 'organizer' check (member_role in ('organizer', 'lead')),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  unique (club_id, user_id)
);

create index idx_club_members_user on club_members (user_id);
create index idx_club_members_club on club_members (club_id);

create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_name text not null,
  colour_hex text not null,
  is_active boolean not null default true
);

create table club_follows (
  user_id uuid not null references profiles (id) on delete cascade,
  club_id uuid not null references clubs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, club_id)
);

create index idx_club_follows_club on club_follows (club_id);

create table category_follows (
  user_id uuid not null references profiles (id) on delete cascade,
  category_id uuid not null references categories (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, category_id)
);

create index idx_category_follows_category on category_follows (category_id);

-- Helper: is the current user a verified, active organizer for club_id?
create or replace function is_verified_organizer_for_club(target_club_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from club_members cm
    where cm.club_id = target_club_id
      and cm.user_id = auth.uid()
      and cm.is_verified = true
  );
$$;

-- Helper: is the current user an admin?
create or replace function is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'
  );
$$;
