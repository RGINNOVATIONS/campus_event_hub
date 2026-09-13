-- CampusPulse: Add delete policy for organizers
-- Migration: 20260815000002_add_event_delete_policy.sql

-- Allows an organizer to delete an event ONLY if:
-- 1. They are a verified organizer for the club that owns the event.
-- 2. The event is in 'draft', 'pending_approval', or 'rejected' status.
-- Events that are 'published', 'completed', or 'cancelled' cannot be deleted to preserve historical data.

create policy "events_delete_organizer" on events for delete
  using (is_verified_organizer_for_club(club_id) and status in ('draft', 'pending_approval', 'rejected'));
