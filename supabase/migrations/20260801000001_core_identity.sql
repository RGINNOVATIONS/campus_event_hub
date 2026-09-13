-- CampusPulse: core identity tables
create extension if not exists "pgcrypto";

-- Generic updated_at trigger function, reused by every table below.
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- allowed_email_domains: configurable college-domain allowlist.
-- Nothing in the app hard-codes a guessed institution domain; add rows
-- here during setup (see README "Allowed college-domain configuration").
-- ---------------------------------------------------------------------
create table allowed_email_domains (
  id uuid primary key default gen_random_uuid(),
  domain text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index idx_allowed_email_domains_active on allowed_email_domains (is_active);

-- ---------------------------------------------------------------------
-- profiles: 1:1 with auth.users. Never stores a password.
-- ---------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  college_email text not null unique,
  college_id text not null,
  department text not null,
  academic_year text not null,
  role text not null default 'student' check (role in ('student', 'organizer', 'admin')),
  email_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_profiles_role on profiles (role);

create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- Prevents a student from ever writing their own `role` column, even
-- through a well-formed UPDATE the client is otherwise allowed to send.
-- Only a caller already holding the `admin` role may change a role.
create or replace function protect_role_column()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> old.role then
    if not exists (
      select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'
    ) then
      raise exception 'Only an administrator may change a role.';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_protect_role_column
  before update on profiles
  for each row execute function protect_role_column();

-- Auto-create a profile row when a new auth user is confirmed to sign up.
-- full_name/college_id/department/academic_year arrive via user metadata
-- at signUp() time from the registration form.
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, college_email, college_id, department, academic_year, role, email_verified)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data->>'college_id', ''),
    coalesce(new.raw_user_meta_data->>'department', ''),
    coalesce(new.raw_user_meta_data->>'academic_year', ''),
    'student',
    new.email_confirmed_at is not null
  );
  return new;
end;
$$;

create trigger trg_handle_new_user
  after insert on auth.users
  for each row execute function handle_new_user();

-- Keeps profiles.email_verified in sync when Supabase Auth confirms the email.
create or replace function handle_user_email_verified()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.email_confirmed_at is not null and old.email_confirmed_at is null then
    update public.profiles set email_verified = true where id = new.id;
  end if;
  return new;
end;
$$;

create trigger trg_handle_user_email_verified
  after update on auth.users
  for each row execute function handle_user_email_verified();
