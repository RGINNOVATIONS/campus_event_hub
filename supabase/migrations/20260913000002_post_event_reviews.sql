-- ============================================================
-- Migration: 20260913000002_post_event_reviews.sql
-- Live Project: hwqfmzospluqdnadmhdg
-- Purpose: Post-event student reviews with attendance-gated submission.
--          (Schema applied via SQL editor; recorded here for repo parity).
-- ============================================================

begin;

-- 1. Table definition
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_reviews_event_user unique (event_id, user_id)
);

-- 2. Indexes
create index if not exists idx_reviews_event on public.reviews (event_id);
create index if not exists idx_reviews_user on public.reviews (user_id);

-- 3. Trigger for updated_at
drop trigger if exists trg_reviews_updated_at on public.reviews;
create trigger trg_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

-- 4. Enable Row Level Security
alter table public.reviews enable row level security;

-- 5. RLS Policies
drop policy if exists "reviews_select" on public.reviews;
create policy "reviews_select" on public.reviews for select
  using (
    user_id = auth.uid()
    or is_admin()
    or exists (
      select 1 from public.events e
      where e.id = reviews.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  );

drop policy if exists "reviews_insert" on public.reviews;
create policy "reviews_insert" on public.reviews for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.enrolments en
      where en.event_id = reviews.event_id
        and en.user_id = auth.uid()
        and en.attendance_status = 'attended'
    )
    and exists (
      select 1 from public.events e
      where e.id = reviews.event_id
        and (e.end_at <= now() or e.status = 'completed')
        and e.status not in ('draft', 'pending_approval', 'rejected', 'cancelled')
    )
  );

drop policy if exists "reviews_update" on public.reviews;
create policy "reviews_update" on public.reviews for update
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.enrolments en
      where en.event_id = reviews.event_id
        and en.user_id = auth.uid()
        and en.attendance_status = 'attended'
    )
    and exists (
      select 1 from public.events e
      where e.id = reviews.event_id
        and (e.end_at <= now() or e.status = 'completed')
        and e.status not in ('draft', 'pending_approval', 'rejected', 'cancelled')
    )
  );

drop policy if exists "reviews_delete" on public.reviews;
create policy "reviews_delete" on public.reviews for delete
  using (is_admin());

-- 6. SECURITY DEFINER RPC for atomic submission & validation
create or replace function public.submit_event_review(
  p_event_id uuid,
  p_rating integer,
  p_comment text default ''::text
)
returns public.reviews
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_enrolment public.enrolments%rowtype;
  v_event public.events%rowtype;
  v_review public.reviews%rowtype;
begin
  if v_uid is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;

  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5.' using errcode = 'P0001';
  end if;

  if char_length(p_comment) > 1000 then
    raise exception 'Comment cannot exceed 1000 characters.' using errcode = 'P0001';
  end if;

  -- 1. Validate event has ended (end_at <= now() or status = 'completed')
  select * into v_event from public.events where id = p_event_id;
  if v_event.id is null then
    raise exception 'Event not found.' using errcode = 'P0002';
  end if;

  if v_event.status in ('draft', 'pending_approval', 'rejected', 'cancelled') then
    raise exception 'Reviews cannot be submitted for this event.' using errcode = 'P0001';
  end if;

  if v_event.end_at > now() and v_event.status <> 'completed' then
    raise exception 'Reviews are only open after the event has ended.' using errcode = 'P0001';
  end if;

  -- 2. Validate attendance server-side
  select * into v_enrolment from public.enrolments
    where event_id = p_event_id and user_id = v_uid;

  if v_enrolment.id is null then
    raise exception 'You are not enrolled in this event.' using errcode = 'P0001';
  end if;

  if v_enrolment.attendance_status <> 'attended' then
    raise exception 'Only students who attended this event can submit a review.' using errcode = 'P0001';
  end if;

  -- 3. Idempotent upsert
  insert into public.reviews (event_id, user_id, rating, comment, updated_at)
  values (p_event_id, v_uid, p_rating, coalesce(trim(p_comment), ''), now())
  on conflict (event_id, user_id) do update
    set rating = excluded.rating,
        comment = excluded.comment,
        updated_at = now()
  returning * into v_review;

  return v_review;
end;
$$;

grant execute on function public.submit_event_review(uuid, integer, text) to authenticated;

commit;
