-- CampusPulse: Rollback script for 20260830000001_extend_student_profile_registration.sql
-- Fully idempotent: safe to execute multiple times.

begin;

-- 1. Restore legacy handle_new_user() trigger function
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, college_email, college_id, department, academic_year, role, email_verified)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data->>'college_id', new.raw_user_meta_data->>'student_id', ''),
    coalesce(new.raw_user_meta_data->>'department', new.raw_user_meta_data->>'branch', ''),
    coalesce(new.raw_user_meta_data->>'academic_year', ''),
    'student',
    new.email_confirmed_at is not null
  );
  return new;
end;
$$;

-- 2. Rename student_id back to college_id if student_id exists and college_id does not
do $$
begin
  if exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'student_id'
  ) and not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'college_id'
  ) then
    alter table public.profiles rename column student_id to college_id;
  end if;
end $$;

-- 3. Drop newly added columns
alter table public.profiles drop column if exists roll_no;
alter table public.profiles drop column if exists programme;
alter table public.profiles drop column if exists branch;

commit;
