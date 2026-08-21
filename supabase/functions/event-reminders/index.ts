// supabase/functions/event-reminders/index.ts
//
// Intended to run on a schedule (see docs/DEPLOYMENT.md — "Scheduled
// reminder setup") roughly every 15-30 minutes. Finds enrolments for
// events starting in the next ~24h that haven't been reminded yet,
// inserts an in-app notification, and forwards it to fcm-send.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async () => {
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const windowStart = new Date(Date.now() + 23 * 60 * 60 * 1000).toISOString();
  const windowEnd = new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString();

  const { data: events, error } = await admin
    .from('events')
    .select('id, title, start_at, venue')
    .eq('status', 'published')
    .gte('start_at', windowStart)
    .lte('start_at', windowEnd);
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });

  let remindersSent = 0;
  for (const event of events ?? []) {
    const { data: enrolments } = await admin
      .from('enrolments')
      .select('user_id')
      .eq('event_id', event.id);

    for (const enrolment of enrolments ?? []) {
      // Idempotency: skip if a reminder notification for this event+user
      // was already created (checked by type+event_id+user_id).
      const { data: existing } = await admin
        .from('notifications')
        .select('id')
        .eq('user_id', enrolment.user_id)
        .eq('event_id', event.id)
        .eq('type', 'event_reminder_24h')
        .maybeSingle();
      if (existing) continue;

      await admin.from('notifications').insert({
        user_id: enrolment.user_id,
        type: 'event_reminder_24h',
        title: `${event.title} starts in ~24 hours`,
        body: `Don't forget: ${event.venue}, tomorrow around this time.`,
        event_id: event.id,
      });

      await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/fcm-send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({
          user_id: enrolment.user_id,
          title: `${event.title} starts in ~24 hours`,
          body: `Don't forget: ${event.venue}.`,
          event_id: event.id,
        }),
      });
      remindersSent++;
    }
  }

  return new Response(JSON.stringify({ remindersSent }), { status: 200 });
});
