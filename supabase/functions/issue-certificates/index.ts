// supabase/functions/issue-certificates/index.ts
//
// Called by an organizer (via the app, which invokes this function with
// the user's JWT) once an event is marked 'completed'. Only ever
// processes enrolments with attendance_status = 'attended'. Idempotent:
// re-invoking for the same event skips students who already have a
// certificate row (unique (event_id, user_id) constraint is the
// ultimate guarantee).
//
// Required secrets:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1';

interface IssueRequest {
  event_id: string;
}

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userErr } = await callerClient.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), { status: 401 });
    }

    const { event_id }: IssueRequest = await req.json();
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: event, error: eventErr } = await admin
      .from('events')
      .select('id, title, club_id, start_at, status, clubs(name)')
      .eq('id', event_id)
      .single();
    if (eventErr || !event) {
      return new Response(JSON.stringify({ error: 'Event not found' }), { status: 404 });
    }
    if (event.status !== 'completed') {
      return new Response(JSON.stringify({ error: 'Event is not completed yet' }), { status: 400 });
    }

    // Authorization: caller must be a verified organizer of this club, or admin.
    const { data: isAuthorized } = await callerClient.rpc('is_verified_organizer_for_club', {
      target_club_id: event.club_id,
    });
    const { data: isAdminUser } = await callerClient.rpc('is_admin');
    if (!isAuthorized && !isAdminUser) {
      return new Response(JSON.stringify({ error: 'Not authorized for this club' }), { status: 403 });
    }

    const { data: attendees, error: attErr } = await admin
      .from('enrolments')
      .select('user_id, profiles(full_name)')
      .eq('event_id', event_id)
      .eq('attendance_status', 'attended');
    if (attErr) throw attErr;

    const { data: alreadyIssued } = await admin
      .from('certificates')
      .select('user_id')
      .eq('event_id', event_id);
    const alreadyIssuedIds = new Set((alreadyIssued ?? []).map((c) => c.user_id));

    const results: { user_id: string; status: string }[] = [];

    for (const attendee of attendees ?? []) {
      if (alreadyIssuedIds.has(attendee.user_id)) {
        results.push({ user_id: attendee.user_id, status: 'already_issued' });
        continue;
      }

      const code = crypto.randomUUID().replace(/-/g, '').slice(0, 12).toUpperCase();
      const fullName = (attendee as any).profiles?.full_name ?? 'Student';
      const clubName = (event as any).clubs?.name ?? '';

      const pdfBytes = await buildCertificatePdf({
        studentName: fullName,
        eventTitle: event.title,
        clubName,
        eventDate: new Date(event.start_at).toDateString(),
        certificateCode: code,
        issueDate: new Date().toDateString(),
      });

      const path = `${event_id}/${attendee.user_id}.pdf`;
      const { error: uploadErr } = await admin.storage
        .from('certificates')
        .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true });
      if (uploadErr) {
        results.push({ user_id: attendee.user_id, status: `upload_failed: ${uploadErr.message}` });
        continue;
      }

      const { error: insertErr } = await admin.from('certificates').insert({
        event_id,
        user_id: attendee.user_id,
        certificate_code: code,
        pdf_path: path,
        issued_by: userData.user.id,
      });
      results.push({
        user_id: attendee.user_id,
        status: insertErr ? `db_failed: ${insertErr.message}` : 'issued',
      });
    }

    return new Response(JSON.stringify({ results }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});

async function buildCertificatePdf(opts: {
  studentName: string;
  eventTitle: string;
  clubName: string;
  eventDate: string;
  certificateCode: string;
  issueDate: string;
}): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  const page = doc.addPage([842, 595]); // A4 landscape
  const gold = rgb(0.831, 0.686, 0.216);
  const dark = rgb(0.03, 0.03, 0.03);
  const font = await doc.embedFont(StandardFonts.HelveticaBold);
  const bodyFont = await doc.embedFont(StandardFonts.Helvetica);

  page.drawRectangle({ x: 0, y: 0, width: 842, height: 595, color: dark });
  page.drawRectangle({ x: 20, y: 20, width: 802, height: 555, borderColor: gold, borderWidth: 2 });

  page.drawText('Campus Event Hub', { x: 340, y: 500, size: 22, font, color: gold });
  page.drawText('Certificate of Participation', { x: 250, y: 450, size: 26, font, color: rgb(0.97, 0.97, 0.97) });
  page.drawText(opts.studentName, { x: 300, y: 380, size: 22, font, color: gold });
  page.drawText(`has participated in "${opts.eventTitle}"`, { x: 180, y: 340, size: 14, font: bodyFont, color: rgb(0.9, 0.9, 0.9) });
  page.drawText(`organized by ${opts.clubName} on ${opts.eventDate}`, { x: 180, y: 315, size: 14, font: bodyFont, color: rgb(0.9, 0.9, 0.9) });
  page.drawText(`Certificate Code: ${opts.certificateCode}`, { x: 60, y: 80, size: 11, font: bodyFont, color: rgb(0.7, 0.7, 0.7) });
  page.drawText(`Issued: ${opts.issueDate}`, { x: 60, y: 62, size: 11, font: bodyFont, color: rgb(0.7, 0.7, 0.7) });
  page.drawText('Authorized Signature: ____________________', { x: 560, y: 62, size: 11, font: bodyFont, color: rgb(0.7, 0.7, 0.7) });

  return await doc.save();
}
