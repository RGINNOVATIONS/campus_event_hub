-- ============================================================
-- Rollback Migration: 20260913000002_post_event_reviews_rollback.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Rollback post-event reviews table, RLS policies, and RPC.
-- ============================================================

begin;

-- 1. Revoke and drop RPC
revoke execute on function public.submit_event_review(uuid, integer, text) from authenticated;
drop function if exists public.submit_event_review(uuid, integer, text);

-- 2. Drop RLS policies
drop policy if exists "reviews_delete" on public.reviews;
drop policy if exists "reviews_update" on public.reviews;
drop policy if exists "reviews_insert" on public.reviews;
drop policy if exists "reviews_select" on public.reviews;

-- 3. Drop trigger
drop trigger if exists trg_reviews_updated_at on public.reviews;

-- 4. Drop table (cascades indexes and constraints)
drop table if exists public.reviews cascade;

commit;
