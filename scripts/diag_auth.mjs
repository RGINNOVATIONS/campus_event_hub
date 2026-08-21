import * as fs from 'fs';

const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseUrl = envVars['SUPABASE_URL'];

async function go(path, method = 'GET', body = null) {
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json',
      'X-Client-Info': 'supabase-js/2.0.0'
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${supabaseUrl}/auth/v1${path}`, opts);
  const text = await res.text();
  try { return { status: res.status, data: JSON.parse(text) }; }
  catch(e) { return { status: res.status, data: text }; }
}

async function main() {
  const creds = JSON.parse(fs.readFileSync('qa_credentials.json', 'utf8'));
  
  // The /admin/users?email= lookup is failing with 500 but health passes.
  // Use generate_link instead - it works email by email and auto-confirms
  const accounts = [
    { email: 'gurjot.singh2@nmims.in', pass: creds['gurjot.singh2@nmims.in'], name: 'QA Student' },
    { email: 'swapnil.mahajan@nmims.edu', pass: creds['swapnil.mahajan@nmims.edu'], name: 'QA Organizer' },
    { email: 'xyz@nmims.edu', pass: 'QaAdmin2024A1!', name: 'QA Admin' },
  ];

  for (const acc of accounts) {
    console.log(`\n--- ${acc.email} ---`);
    
    // Try generate_link with type=signup - this also creates users if not exists
    const r = await go('/admin/generate_link', 'POST', {
      type: 'magiclink',
      email: acc.email
    });
    console.log(`generate_link: status=${r.status}`, JSON.stringify(r.data).substring(0, 300));
  }
  
  // Try listing users with page param
  console.log('\n--- Listing users with page=1 ---');
  const listR = await go('/admin/users?page=1&per_page=10');
  console.log(`status=${listR.status}`, JSON.stringify(listR.data).substring(0, 500));

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
