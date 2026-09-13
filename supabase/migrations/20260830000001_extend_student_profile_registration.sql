-- CampusPulse: Extend student registration and profiles table
-- Migration: 20260830000001_extend_student_profile_registration.sql
-- Fully idempotent: safe to execute multiple times on fresh or existing databases.

begin;

-- 1. Rename college_id to student_id on public.profiles only if college_id exists and student_id does not
do $$
begin
  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'college_id'
  ) and not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'student_id'
  ) then
    alter table public.profiles rename column college_id to student_id;
  end if;
end $$;

-- 2. Add columns as nullable initially to allow safe backfill (covers fresh install where student_id wasn't created via rename)
alter table public.profiles add column if not exists student_id text;
alter table public.profiles add column if not exists roll_no text;
alter table public.profiles add column if not exists programme text;
alter table public.profiles add column if not exists branch text;

-- 3. Backfill existing rows with 'N/A' placeholder before enforcing NOT NULL
update public.profiles set student_id = 'N/A' where student_id is null;
update public.profiles set roll_no = 'N/A' where roll_no is null;
update public.profiles set programme = 'N/A' where programme is null;
update public.profiles set branch = 'N/A' where branch is null;

-- 4. Enforce NOT NULL constraints (guarded so re-running on NOT NULL columns is safe)
do $$
begin
  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' 
      and column_name = 'student_id' and is_nullable = 'YES'
  ) then
    alter table public.profiles alter column student_id set not null;
  end if;

  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' 
      and column_name = 'roll_no' and is_nullable = 'YES'
  ) then
    alter table public.profiles alter column roll_no set not null;
  end if;

  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' 
      and column_name = 'programme' and is_nullable = 'YES'
  ) then
    alter table public.profiles alter column programme set not null;
  end if;

  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' 
      and column_name = 'branch' and is_nullable = 'YES'
  ) then
    alter table public.profiles alter column branch set not null;
  end if;
end $$;

-- 5. Update handle_new_user() trigger function
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch text;
  v_dept text;
begin
  v_branch := coalesce(new.raw_user_meta_data->>'branch', 'N/A');
  v_dept := coalesce(new.raw_user_meta_data->>'department', v_branch);
  if v_dept is null or trim(v_dept) = '' then
    v_dept := v_branch;
  end if;

  insert into public.profiles (
    id,
    full_name,
    college_email,
    student_id,
    roll_no,
    programme,
    branch,
    department,
    academic_year,
    role,
    email_verified
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data->>'student_id', new.raw_user_meta_data->>'college_id', 'N/A'),
    coalesce(new.raw_user_meta_data->>'roll_no', 'N/A'),
    coalesce(new.raw_user_meta_data->>'programme', 'N/A'),
    v_branch,
    v_dept,
    coalesce(new.raw_user_meta_data->>'academic_year', 'First Year'),
    'student',
    new.email_confirmed_at is not null
  );
  return new;
end;
$$;

commit;
