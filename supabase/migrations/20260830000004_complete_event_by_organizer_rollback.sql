-- ============================================================
-- Migration: 20260830000004_complete_event_by_organizer_rollback.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Rollback changes from 20260830000004_complete_event_by_organizer.sql
-- ============================================================

begin;

drop function if exists public.complete_event_by_organizer(uuid);

commit;
