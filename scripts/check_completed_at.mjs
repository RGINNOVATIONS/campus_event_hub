import * as fs from 'fs';

// Read .env
const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

const anonKey = envVars['SUPABASE_ANON_KEY'];
const supabaseUrl = envVars['SUPABASE_URL'];

async function rest(path) {
  const opts = {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${anonKey}`,
      'apikey': anonKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    }
  };
  const res = await fetch(`${supabaseUrl}/rest/v1${path}`, opts);
  const text = await res.text();
  try { return { status: res.status, data: JSON.parse(text) }; }
  catch(e) { return { status: res.status, data: text }; }
}

async function main() {
  console.log('=== Checking events.completed_at on live ===');
  const res = await rest('/events?select=id,title,status,completed_at&limit=2');
  console.log('Status:', res.status);
  console.log('Data:', JSON.stringify(res.data, null, 2));
}

main().catch(console.error);
