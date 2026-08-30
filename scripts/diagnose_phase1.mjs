import * as fs from 'fs';

// Read .env
const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || envVars['SUPABASE_SERVICE_ROLE_KEY'];
const anonKey = envVars['SUPABASE_ANON_KEY'];
const apiKey = serviceRoleKey || anonKey;
const supabaseUrl = envVars['SUPABASE_URL'];

async function rest(path, method = 'GET', body = null) {
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'apikey': apiKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${supabaseUrl}/rest/v1${path}`, opts);
  const text = await res.text();
  try { return { status: res.status, data: JSON.parse(text) }; }
  catch(e) { return { status: res.status, data: text }; }
}

async function checkRpc(rpcName, params = {}) {
  const opts = {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'apikey': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(params)
  };
  const res = await fetch(`${supabaseUrl}/rest/v1/rpc/${rpcName}`, opts);
  const text = await res.text();
  return { status: res.status, text };
}

async function main() {
  console.log('=== PHASE 1: DETAILED DIAGNOSTIC AUDIT ===');
  console.log('Supabase URL:', supabaseUrl);

  // 1. Events table without postponement_reason
  console.log('\n--- 1. Events Table (Base fields) ---');
  const eventsRes = await rest('/events?select=id,title,club_id,status,created_by,start_at,end_at,registration_deadline');
  console.log('Events:', JSON.stringify(eventsRes.data, null, 2));

  // 2. Check RPCs with exact parameter signatures
  console.log('\n--- 2. RPC Checks with signatures ---');
  
  // postpone_event_by_organizer
  const rpcPostpone = await checkRpc('postpone_event_by_organizer', {
    p_event_id: '00000000-0000-0000-0000-000000000000',
    p_start_at: '2026-09-01T10:00:00Z',
    p_end_at: '2026-09-01T12:00:00Z',
    p_registration_deadline: '2026-09-01T09:00:00Z',
    p_postponement_reason: 'Test reason'
  });
  console.log('RPC postpone_event_by_organizer (with args):', rpcPostpone.status, rpcPostpone.text);

  // delete_event_by_organizer
  const rpcDelete = await checkRpc('delete_event_by_organizer', {
    p_event_id: '00000000-0000-0000-0000-000000000000'
  });
  console.log('RPC delete_event_by_organizer (with args):', rpcDelete.status, rpcDelete.text);

  // update_event_by_organizer
  const rpcUpdate = await checkRpc('update_event_by_organizer', {
    p_event_id: '00000000-0000-0000-0000-000000000000',
    p_title: 'Test',
    p_short_description: 'Test',
    p_full_description: 'Test',
    p_category_id: '00000000-0000-0000-0000-000000000000',
    p_venue: 'Test',
    p_start_at: '2026-09-01T10:00:00Z',
    p_end_at: '2026-09-01T12:00:00Z',
    p_registration_deadline: '2026-09-01T09:00:00Z'
  });
  console.log('RPC update_event_by_organizer (with args):', rpcUpdate.status, rpcUpdate.text);

  // is_verified_organizer_for_club
  const rpcIsVerified = await checkRpc('is_verified_organizer_for_club', {
    target_club_id: '11111111-1111-1111-1111-111111111111'
  });
  console.log('RPC is_verified_organizer_for_club (with target_club_id):', rpcIsVerified.status, rpcIsVerified.text);

  const rpcIsVerified2 = await checkRpc('is_verified_organizer_for_club', {
    club_id: '11111111-1111-1111-1111-111111111111'
  });
  console.log('RPC is_verified_organizer_for_club (with club_id):', rpcIsVerified2.status, rpcIsVerified2.text);
}

main().catch(console.error);
