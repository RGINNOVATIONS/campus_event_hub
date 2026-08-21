import * as fs from 'fs';
import * as path from 'path';

const envContent = fs.readFileSync(path.resolve('.env'), 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!serviceRoleKey) {
  console.error('ERROR: SUPABASE_SERVICE_ROLE_KEY env var not set.');
  process.exit(1);
}

const supabaseUrl = envVars['SUPABASE_URL'];

async function adminFetch(path, method = 'GET', body = null) {
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json'
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${supabaseUrl}/auth/v1${path}`, opts);
  const text = await res.text();
  try { return { status: res.status, data: JSON.parse(text) }; }
  catch (e) { return { status: res.status, data: text }; }
}

async function main() {
  console.log('\n=== Listing Auth Users via REST ===');
  const list = await adminFetch('/admin/users?per_page=50');
  if (list.status !== 200) {
    console.error('List users failed:', list.status, JSON.stringify(list.data));
    process.exit(1);
  }
  
  const users = list.data.users || [];
  console.log(`Found ${users.length} auth users`);

  const targets = [
    'gurjot.singh2@nmims.in',
    'swapnil.mahajan@nmims.edu',
    'xyz@nmims.edu'
  ];

  for (const email of targets) {
    const user = users.find(u => u.email === email);
    if (!user) {
      console.log(`\nUser ${email} NOT FOUND in auth.users`);
      // Create it
      console.log(`Creating ${email}...`);
      const creds = JSON.parse(fs.readFileSync('qa_credentials.json','utf8'));
      const pass = creds[email] || 'QaUser2024A1!';
      const createRes = await adminFetch('/admin/users', 'POST', {
        email,
        password: pass,
        email_confirm: true,
        user_metadata: { full_name: email.includes('xyz') ? 'QA Admin' : email.includes('gurjot') ? 'QA Student' : 'QA Organizer' }
      });
      if (createRes.status === 200 || createRes.status === 201) {
        console.log(`  Created ${email}, ID: ${createRes.data.id}`);
        if (!creds[email]) {
          creds[email] = pass;
          fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
        }
      } else {
        console.error(`  Create failed:`, createRes.status, JSON.stringify(createRes.data));
      }
      continue;
    }

    console.log(`\nUser: ${email}`);
    console.log(`  ID: ${user.id}`);
    console.log(`  email_confirmed_at: ${user.email_confirmed_at || 'NOT CONFIRMED'}`);

    if (!user.email_confirmed_at) {
      console.log(`  Confirming email...`);
      const upd = await adminFetch(`/admin/users/${user.id}`, 'PUT', { email_confirm: true });
      if (upd.status === 200) {
        console.log(`  ✅ Email confirmed`);
      } else {
        console.error(`  ❌ Confirm failed:`, upd.status, JSON.stringify(upd.data));
      }
    } else {
      console.log(`  ✅ Already confirmed`);
    }
  }

  // Re-list to confirm
  console.log('\n=== Final Auth User Status ===');
  const list2 = await adminFetch('/admin/users?per_page=50');
  const users2 = list2.data.users || [];
  for (const email of targets) {
    const u = users2.find(u => u.email === email);
    if (u) {
      console.log(`${email}: confirmed=${!!u.email_confirmed_at}, id=${u.id}`);
    } else {
      console.log(`${email}: NOT FOUND`);
    }
  }
  
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
