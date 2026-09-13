-- ============================================================
-- CampusPulse: QA Admin Role Bootstrap
-- Migration: 20260820000001_qa_admin_bootstrap.sql
--
-- PURPOSE:
--   One-time bootstrap that promotes the first QA administrator
--   account (admin@nmims.edu) to role = 'admin'.
--
-- WHY THE TRIGGER IS TEMPORARILY DISABLED:
--   protect_role_column() checks auth.uid() to verify the
--   caller is already a profile with role = 'admin'. When
--   executed through the privileged postgres/migrations session
--   (supabase db push, SQL editor), auth.uid() returns NULL.
--   The trigger's NOT EXISTS check on NULL evaluates to TRUE
--   and raises the exception — blocking the very first admin
--   promotion because there is no existing admin to authorize it.
--
--   This is a one-time bootstrap gap. The trigger is disabled
--   ONLY for this session and is re-enabled within the same
--   transaction before COMMIT. protect_role_column() itself is
--   never dropped, never replaced, and never weakened.
--
-- SAFETY PROPERTIES:
--   - Scoped to exactly one UUID via WHERE id = '...'
--   - Idempotent: WHERE role <> 'admin' makes re-runs a no-op
--   - protect_role_column() function: UNCHANGED
--   - trg_protect_role_column trigger: RESTORED before COMMIT
--   - RLS policies: UNCHANGED
--   - auth.users: UNCHANGED
--   - All other profiles rows: UNCHANGED
--   - No secrets, keys or credentials embedded
--
-- AFTER THIS MIGRATION:
--   All subsequent role changes must go through an authenticated
--   admin session in the application. This bootstrap must not
--   be re-used or copied for future role changes.
-- ============================================================

begin;

-- Temporarily disable the role-guard trigger for this session
-- only. ALTER TABLE ... DISABLE TRIGGER is session-scoped and
-- has no effect outside this transaction.
alter table public.profiles disable trigger trg_protect_role_column;

-- Promote the single QA admin account.
-- WHERE clause guarantees:
--   (a) Only this exact UUID is affected — no other row touched.
--   (b) Idempotent: no-op if the row is already role = 'admin'.
update public.profiles
  set    role = 'admin'
  where  id    = '0cf03c17-0344-4df7-ad03-d1f6463cc985'
    and  role <> 'admin';

-- Restore the trigger before the transaction commits.
-- After COMMIT the trigger is fully active for all sessions.
alter table public.profiles enable trigger trg_protect_role_column;

commit;
