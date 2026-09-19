-- 20260914000001_event_reports_rollback.sql
-- Rollback migration for 20260914000001_event_reports.sql

drop policy if exists "event_reports_delete" on public.event_reports;
drop policy if exists "event_reports_update" on public.event_reports;
drop policy if exists "event_reports_insert" on public.event_reports;
drop policy if exists "event_reports_select" on public.event_reports;

drop trigger if exists trg_event_reports_attribution on public.event_reports;
drop function if exists public.set_event_reports_attribution();

drop table if exists public.event_reports cascade;
