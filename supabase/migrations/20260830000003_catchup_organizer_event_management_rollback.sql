-- ============================================================
-- Migration: 20260830000003_catchup_organizer_event_management_rollback.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Rollback changes from trimmed 20260830000003_catchup_organizer_event_management.sql
-- ============================================================

begin;

-- 1. Drop the 3 RPC functions
drop function if exists public.postpone_event_by_organizer(uuid, timestamptz, timestamptz, timestamptz, text);
drop function if exists public.update_event_by_organizer(uuid, text, text, text, uuid, text, timestamptz, timestamptz, timestamptz, text, text, text, text, text, text, text);
drop function if exists public.delete_event_by_organizer(uuid);

-- 2. Restore status check constraint (excluding 'postponed')
do $$
begin
  alter table public.events drop constraint if exists chk_event_status;
exception when others then null;
end $$;

alter table public.events add constraint chk_event_status
  check (status in ('draft', 'pending_approval', 'published', 'rejected', 'cancelled', 'completed'));

-- 3. Drop postponement_reason column if exists
alter table public.events drop column if exists postponement_reason;

commit;
