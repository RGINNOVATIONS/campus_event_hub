-- CampusPulse: rollback event-reports storage bucket
delete from storage.buckets where id = 'event-reports';
