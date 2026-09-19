-- 20260914000001_event_reports.sql
-- Event Reports table, server-side attribution trigger, and RLS policies.
-- Internal document: Only verified club organizers for the event's club OR admins can access.
-- Students have NO access.

-- 1. Create table
create table if not exists public.event_reports (
  event_id uuid primary key references public.events(id) on delete cascade,
  organizer_notes text,
  objectives text,
  outcomes text,
  feedback_narrative text,
  status text not null default 'draft' check (status in ('draft', 'confirmed')),
  created_by uuid references public.profiles(id),
  confirmed_by uuid references public.profiles(id),
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Server-side attribution & updated_at trigger
create or replace function public.set_event_reports_attribution()
returns trigger
language plpgsql
security definer
as $$
begin
  new.updated_at = now();

  -- created_by is permanently set on insert from the authenticated caller
  if tg_op = 'INSERT' then
    new.created_by = auth.uid();
  else
    new.created_by = old.created_by; -- immutable
  end if;

  -- confirmed attribution is strictly tied to status
  if new.status = 'confirmed' then
    new.confirmed_by = auth.uid();
    new.confirmed_at = now();
  else
    new.confirmed_by = null;
    new.confirmed_at = null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_event_reports_attribution on public.event_reports;
create trigger trg_event_reports_attribution
  before insert or update on public.event_reports
  for each row execute function public.set_event_reports_attribution();

-- 3. Enable Row Level Security
alter table public.event_reports enable row level security;

-- 4. RLS Policies (Idempotent: drop-if-exists before create)

-- SELECT: Only verified organizers of the event's club OR admins.
drop policy if exists "event_reports_select" on public.event_reports;
create policy "event_reports_select" on public.event_reports for select
  using (
    is_admin()
    or exists (
      select 1 from public.events e
      where e.id = event_reports.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  );

-- INSERT: Only verified organizers of the event's club OR admins.
drop policy if exists "event_reports_insert" on public.event_reports;
create policy "event_reports_insert" on public.event_reports for insert
  with check (
    is_admin()
    or exists (
      select 1 from public.events e
      where e.id = event_reports.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  );

-- UPDATE: Only verified organizers of the event's club OR admins.
drop policy if exists "event_reports_update" on public.event_reports;
create policy "event_reports_update" on public.event_reports for update
  using (
    is_admin()
    or exists (
      select 1 from public.events e
      where e.id = event_reports.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  )
  with check (
    is_admin()
    or exists (
      select 1 from public.events e
      where e.id = event_reports.event_id
        and is_verified_organizer_for_club(e.club_id)
    )
  );

-- DELETE: Admin-only. Organizers cannot delete official report rows.
-- Deletion of the parent event cascades automatically.
drop policy if exists "event_reports_delete" on public.event_reports;
create policy "event_reports_delete" on public.event_reports for delete
  using (is_admin());
