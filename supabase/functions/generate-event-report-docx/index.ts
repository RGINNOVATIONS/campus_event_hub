// supabase/functions/generate-event-report-docx/index.ts
//
// Generates an official Word Document (.docx) from a CONFIRMED Event Report
// using docx library, uploads to the 'event-reports' storage bucket (with upsert: true),
// and returns a short-lived signed download URL.
//
// Required secrets:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  buildReportDocx,
  computeBreakdown,
  parseGuests,
} from './report_helpers.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface GenerateDocxRequest {
  event_id: string;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Authenticate caller JWT
    const authHeader = req.headers.get('Authorization') ?? '';
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userErr } = await callerClient.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Parse request
    const body: GenerateDocxRequest = await req.json();
    const eventId = body.event_id;
    if (!eventId) {
      return new Response(JSON.stringify({ error: 'event_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Elevated service client
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 4. Fetch Event & Club
    const { data: event, error: eventErr } = await admin
      .from('events')
      .select('id, title, full_description, club_id, status, start_at, end_at, venue, guests, categories(name), clubs(name, contact_email)')
      .eq('id', eventId)
      .single();

    if (eventErr || !event) {
      return new Response(JSON.stringify({ error: 'Event not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (event.status !== 'completed') {
      return new Response(JSON.stringify({ error: 'Event is not completed yet' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 5. Authorization Check: Verified Organizer for Club OR Admin
    const { data: isAuthorized } = await callerClient.rpc('is_verified_organizer_for_club', {
      target_club_id: event.club_id,
    });
    const { data: isAdminUser } = await callerClient.rpc('is_admin');
    if (!isAuthorized && !isAdminUser) {
      return new Response(JSON.stringify({ error: 'Not authorized for this club' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 6. Report Status Gate: MUST BE 'confirmed'
    const { data: report, error: reportErr } = await admin
      .from('event_reports')
      .select('*')
      .eq('event_id', eventId)
      .maybeSingle();

    if (reportErr || !report) {
      return new Response(
        JSON.stringify({ error: 'No report has been created for this event yet.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (report.status !== 'confirmed') {
      return new Response(
        JSON.stringify({
          error: 'Event report is still in draft state. The report must be reviewed and confirmed as final before downloading.',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 7. Gather Enrolments & Attendance Data
    const { data: enrolmentsData } = await admin
      .from('enrolments')
      .select('id, attendance_status, profiles!user_id(programme, branch, academic_year)')
      .eq('event_id', eventId);

    const enrolments = enrolmentsData ?? [];
    const registrationsCount = enrolments.length;
    const attendedList = enrolments.filter((e) => e.attendance_status === 'attended');
    const attendanceCount = attendedList.length;
    const attendancePercentage = registrationsCount > 0
      ? ((attendanceCount / registrationsCount) * 100).toFixed(1)
      : '0.0';

    // Demographic breakdowns (Attended students)
    const programmeBreakdown = computeBreakdown(attendedList.map((e) => (e as any).profiles?.programme));
    const branchBreakdown = computeBreakdown(attendedList.map((e) => (e as any).profiles?.branch));
    const yearBreakdown = computeBreakdown(attendedList.map((e) => (e as any).profiles?.academic_year));

    // 8. Gather Guests (from events.guests JSONB column)
    const guests = parseGuests(event.guests);

    // 9. Gather Reviews & Ratings
    const { data: reviewsData } = await admin
      .from('reviews')
      .select('rating, comment')
      .eq('event_id', eventId);
    const reviewsList = reviewsData ?? [];
    const avgRating = reviewsList.length > 0
      ? (reviewsList.reduce((acc, curr) => acc + (curr.rating ?? 0), 0) / reviewsList.length).toFixed(1)
      : 'N/A';
    const ratingDist: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    for (const r of reviewsList) {
      if (r.rating && ratingDist[r.rating] !== undefined) {
        ratingDist[r.rating]++;
      }
    }

    // 10. Gather Organizer / Confirmer Profile
    let confirmedByName = 'Authorized Club Organizer';
    if (report.confirmed_by) {
      const { data: confirmerProfile } = await admin
        .from('profiles')
        .select('full_name')
        .eq('id', report.confirmed_by)
        .maybeSingle();
      if (confirmerProfile?.full_name) {
        confirmedByName = confirmerProfile.full_name;
      }
    }

    // 11. Build Document
    const docxBytes = await buildReportDocx({
      event,
      report,
      registrationsCount,
      attendanceCount,
      attendancePercentage,
      programmeBreakdown,
      branchBreakdown,
      yearBreakdown,
      guests,
      avgRating,
      reviewCount: reviewsList.length,
      ratingDist,
      confirmedByName,
    });

    // 12. Upload to Storage with upsert: true (one canonical file per event)
    const path = `${eventId}/event_report_${eventId}.docx`;
    const { error: uploadErr } = await admin.storage
      .from('event-reports')
      .upload(path, docxBytes, {
        contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        upsert: true,
      });

    if (uploadErr) {
      return new Response(
        JSON.stringify({ error: `Storage upload failed: ${uploadErr.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 13. Create Signed URL (300 seconds)
    const { data: signedData, error: signedErr } = await admin.storage
      .from('event-reports')
      .createSignedUrl(path, 300);

    if (signedErr || !signedData?.signedUrl) {
      return new Response(
        JSON.stringify({ error: 'Failed to create download URL' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const safeTitle = (event.title ?? 'Event')
      .replace(/[^a-zA-Z0-9_-]/g, '_')
      .slice(0, 40);
    const fileName = `Event_Report_${safeTitle}.docx`;

    return new Response(
      JSON.stringify({
        signed_url: signedData.signedUrl,
        file_name: fileName,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
