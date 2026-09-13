-- CampusPulse: close a real gap found on audit — handle_new_user() never
-- checked allowed_email_domains, so a client that called
-- supabase.auth.signUp() directly (bypassing the Flutter app's
-- CollegeEmailValidator, which is client-side only) could register with
-- any email domain at all. Client-side validation is a UX nicety, not
-- enforcement — the spec is explicit that hiding a check in the UI is
-- not authorization, and the same principle applies to any check that
-- only lives in the client.
--
-- This is a forward migration rather than an edit to
-- 20260801000001_core_identity.sql, per the instruction to prefer
-- forward migrations over rewriting deployed history when a project's
-- deployment status can't be confirmed. (In this project's actual case
-- nothing has ever been deployed — see TASKS.md section 0 — but the
-- forward-migration approach costs nothing and removes any ambiguity
-- for whoever runs this against a real project.)
--
-- Raising an exception inside an AFTER INSERT trigger on auth.users
-- rolls back the entire signup transaction, including the auth.users
-- row itself — so a disallowed-domain signUp() call fails outright
-- rather than silently succeeding with an orphaned or invalid profile.

create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_domain text;
  v_allowed boolean;
begin
  v_domain := lower(split_part(new.email, '@', 2));

  select exists (
    select 1 from allowed_email_domains d
    where d.is_active = true and lower(d.domain) = v_domain
  ) into v_allowed;

  if not v_allowed then
    raise exception
      'Registration is restricted to approved college email domains. % is not an approved domain.',
      v_domain
      using errcode = 'P0001';
  end if;

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

-- Trigger definition is unchanged (still AFTER INSERT on auth.users,
-- still calls handle_new_user()) — only the function body changed via
-- CREATE OR REPLACE above, so no DROP/CREATE TRIGGER is needed here.

-- Sanity note for whoever deploys this: if allowed_email_domains is
-- empty (e.g. a fresh project before README section 6.3 has been
-- followed), EVERY signup will be rejected, not silently allowed. This
-- is intentional — fail closed, not open. Insert at least one real
-- domain before enabling public registration.
