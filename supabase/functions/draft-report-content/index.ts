// supabase/functions/draft-report-content/index.ts
//
// AI-assisted drafting of Event Report content (Objectives, Outcomes,
// Feedback Narrative, and Organizer Notes Polish) using Google Gemini API.
//
// Required secrets:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, GEMINI_API_KEY
// Optional secret:
//   GEMINI_MODEL (defaults to 'gemini-3.5-flash-lite')

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ObjectivesRequest {
  mode: 'objectives_and_outcomes';
  event_id: string;
  organizer_notes: string;
  category?: string;
  registrations_count?: number;
  attendance_count?: number;
  attendance_percentage?: number | string;
  guests?: Array<{ name: string; designation: string; organization: string }>;
}

interface NarrativeRequest {
  mode: 'feedback_narrative';
  event_id: string;
}

interface PolishNotesRequest {
  mode: 'polish_notes';
  event_id: string;
  organizer_notes: string;
}

type DraftRequest = ObjectivesRequest | NarrativeRequest | PolishNotesRequest;

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
    const body: DraftRequest = await req.json();
    const eventId = body.event_id;
    if (!eventId) {
      return new Response(JSON.stringify({ error: 'event_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Elevated admin client to fetch event & club details
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: event, error: eventErr } = await admin
      .from('events')
      .select('id, title, full_description, club_id, status, clubs(name)')
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

    // 4. Authorization check: must be verified organizer of this club OR admin
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

    // 5. Read Gemini API key & model
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY secret is not configured on Supabase' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    const model = Deno.env.get('GEMINI_MODEL') ?? 'gemini-3.5-flash-lite';

    // 6. Handle mode
    if (body.mode === 'objectives_and_outcomes') {
      const notes = (body.organizer_notes ?? '').trim();
      if (!notes) {
        return new Response(
          JSON.stringify({ error: 'Organizer notes are required to draft objectives and outcomes.' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      let guestsText = 'Guests: None listed';
      if (body.guests && body.guests.length > 0) {
        guestsText = 'Guests:\n' + body.guests.map((g) => `- ${g.name} (${g.designation}, ${g.organization})`).join('\n');
      }

      const prompt = `You are an academic event reporting assistant for college administrative reports submitted to the Dean and college leadership.
Draft formal, professional "Objectives" and "Key Outcomes & Impact" sections for an official event report based STRICTLY on the provided event facts and the organizer's notes below.

CRITICAL RULES:
1. Do NOT fabricate, invent, or assume any facts, speakers, sponsors, awards, or numbers that are not provided in the inputs.
2. Structure and elevate the organizer's raw notes into formal, executive-ready institutional language.
3. Your output MUST contain two distinct, clearly-headed sections:
## Objectives
(4-6 detailed bullet points, each 1-2 full sentences, written in formal institutional report language suitable for a Dean-level document, starting with action verbs, stating what the event was intended to achieve)

## Key Outcomes & Impact
(4-6 detailed bullet points, each 1-2 full sentences, written in formal institutional report language suitable for a Dean-level document, reflecting what was accomplished, student engagement, and practical impact based on the organizer's account and attendance numbers)

Event Facts:
- Title: ${event.title}
- Organizing Club: ${(event as any).clubs?.name ?? ''}
- Category: ${body.category ?? 'College Event'}
- Description: ${event.full_description ?? 'N/A'}
- Registrations: ${body.registrations_count ?? 'N/A'}
- Attendance: ${body.attendance_count ?? 'N/A'} (${body.attendance_percentage ?? 'N/A'}%)
${guestsText}

Organizer's Account & Notes:
"${notes}"
`;

      const aiText = await callGemini(model, apiKey, prompt, 2048);
      const parsed = parseObjectivesAndOutcomes(aiText);

      return new Response(
        JSON.stringify({
          objectives: parsed.objectives,
          outcomes: parsed.outcomes,
          raw_text: aiText,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    } else if (body.mode === 'feedback_narrative') {
      // 7. Server-side PII stripping: Query ONLY rating and comment from database
      const { data: reviewsData, error: revErr } = await admin
        .from('reviews')
        .select('rating, comment')
        .eq('event_id', eventId);

      if (revErr) throw revErr;

      const reviewsList = reviewsData ?? [];
      const nonBlankReviews = reviewsList.filter((r) => r.comment && r.comment.trim().length > 0);

      if (reviewsList.length === 0) {
        return new Response(
          JSON.stringify({
            narrative: 'No student feedback or ratings were submitted for this event.',
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const totalRating = reviewsList.reduce((acc, curr) => acc + (curr.rating ?? 0), 0);
      const avgRating = totalRating / reviewsList.length;

      if (nonBlankReviews.length === 0) {
        return new Response(
          JSON.stringify({
            narrative: `The event received an average rating of ${avgRating.toFixed(1)} out of 5.0 stars across ${reviewsList.length} student review(s). No written comments were submitted.`,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      // Anonymous reviews snippet: ZERO student names, emails, or IDs sent
      const commentsSnippet = nonBlankReviews
        .map((r, i) => `Review ${i + 1} (${r.rating} stars): "${r.comment.trim()}"`)
        .join('\n');

      const prompt = `You are an academic event reporting assistant preparing a post-event report for college leadership.
Analyze the following ANONYMOUS post-event student reviews and ratings for the event "${event.title}".

Write a concise, professional 1 to 2 paragraph narrative summarizing:
1. Overall student sentiment and reception.
2. Major highlights and recurring praise (e.g. content relevance, organization, speaker quality).
3. Constructive feedback or areas for improvement (if noted).

CRITICAL RULES:
- Do NOT reference individual student identities or invent comments not in the dataset.
- Maintain an objective, constructive, and executive-ready tone suitable for faculty and college leadership.
- Output ONLY the narrative paragraphs, with no extra conversational greeting or sign-off.

Review Statistics:
- Average Rating: ${avgRating.toFixed(1)} / 5.0
- Total Reviews: ${reviewsList.length}

Student Comments:
${commentsSnippet}
`;

      const aiText = await callGemini(model, apiKey, prompt, 1024);

      return new Response(
        JSON.stringify({
          narrative: aiText.trim(),
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    } else if (body.mode === 'polish_notes') {
      const notes = (body.organizer_notes ?? '').trim();
      if (!notes) {
        return new Response(
          JSON.stringify({ error: 'Organizer notes are required to polish.' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const prompt = `You are a writing assistant for academic and administrative college event reports.
Given the following raw organizer notes, return a grammar-corrected, clearly-written version of the SAME content — same facts, same meaning, just cleaner English.

CRITICAL RULES:
1. Do not add any new facts, numbers, or claims not present in the original notes — only correct grammar, clarity, and phrasing.
2. Preserve all specific details, metrics, names, and observations mentioned by the organizer.
3. Output ONLY the polished text, with no extra conversational remarks, prefixes, or quotation marks.

Raw Organizer Notes:
"${notes}"
`;

      const aiText = await callGemini(model, apiKey, prompt, 1024);

      return new Response(
        JSON.stringify({
          polished_notes: aiText.trim(),
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    } else {
      return new Response(
        JSON.stringify({
          error: 'Invalid mode. Must be "objectives_and_outcomes", "feedback_narrative", or "polish_notes".',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

async function callGemini(
  model: string,
  apiKey: string,
  prompt: string,
  maxOutputTokens = 1024,
): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens,
      },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    let message = `Gemini API returned HTTP ${response.status}`;
    try {
      const errJson = JSON.parse(errorBody);
      if (errJson.error?.message) {
        message = errJson.error.message;
      }
    } catch {
      // Use fallback message
    }
    throw new Error(`AI drafting failed: ${message}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || typeof text !== 'string' || text.trim().length === 0) {
    throw new Error('AI drafting service returned an empty response.');
  }

  return text.trim();
}

function parseObjectivesAndOutcomes(rawText: string): { objectives: string; outcomes: string } {
  let objectives = '';
  let outcomes = '';

  const objMatch = rawText.match(/##\s*Objectives([\s\S]*?)(?=##\s*Key Outcomes|##\s*Outcomes|$)/i);
  if (objMatch && objMatch[1]) {
    objectives = objMatch[1].trim();
  }

  const outMatch = rawText.match(/##\s*(?:Key\s+)?Outcomes(?:[\s\S]*?&[\s\S]*?Impact)?([\s\S]*)$/i);
  if (outMatch && outMatch[1]) {
    outcomes = outMatch[1].trim();
  }

  // Fallback if formatting was not segmented
  if (!objectives && !outcomes) {
    objectives = rawText;
  }

  return { objectives, outcomes };
}

