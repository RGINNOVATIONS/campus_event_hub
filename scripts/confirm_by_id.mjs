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
  
  // Known user IDs from generate_link response above
  const knownUsers = [
    { id: '05106768-d86e-458f-b9fd-0f2525560496', email: 'gurjot.singh2@nmims.in' },
    { id: 'f3375d86-9d9c-4747-a23b-b3acd1db0bb3', email: 'swapnil.mahajan@nmims.edu' },
  ];

  console.log('=== Confirming emails by user ID ===');
  for (const user of knownUsers) {
    console.log(`\nConfirming ${user.email} (${user.id})...`);
    const r = await go(`/admin/users/${user.id}`, 'PUT', {
      email_confirm: true
    });
    if (r.status === 200) {
      console.log(`  ✅ Confirmed. email_confirmed_at: ${r.data.email_confirmed_at}`);
    } else {
      console.error(`  ❌ Error ${r.status}:`, JSON.stringify(r.data).substring(0, 200));
    }
  }

  // Create admin via /admin/users endpoint
  console.log('\n=== Creating Admin (xyz@nmims.edu) ===');
  const adminPass = 'QaAdmin2024A1!';
  const adminCreate = await go('/admin/users', 'POST', {
    email: 'xyz@nmims.edu',
    password: adminPass,
    email_confirm: true,
    user_metadata: { full_name: 'QA Admin' }
  });
  
  if (adminCreate.status === 200 || adminCreate.status === 201) {
    console.log(`  ✅ Admin created. ID: ${adminCreate.data.id}`);
    creds['xyz@nmims.edu'] = adminPass;
    fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
  } else {
    console.log(`  Status ${adminCreate.status}:`, JSON.stringify(adminCreate.data).substring(0, 300));
    // Admin may already exist from the SQL insert earlier - try finding via generate_link
    const gl = await go('/admin/generate_link', 'POST', { type: 'magiclink', email: 'xyz@nmims.edu' });
    if (gl.status === 200) {
      console.log(`  Admin user exists. ID: ${gl.data.id}`);
      // Now confirm by ID
      const conf = await go(`/admin/users/${gl.data.id}`, 'PUT', { email_confirm: true });
      console.log(`  Confirm result: ${conf.status}`, conf.status === 200 ? conf.data.email_confirmed_at : JSON.stringify(conf.data).substring(0,100));
      creds['xyz@nmims.edu'] = adminPass;
      fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
    }
  }

  // Verify logins
  console.log('\n=== Verifying Login Credentials ===');
  for (const [email, pass] of Object.entries(creds)) {
    const loginRes = await go('/token?grant_type=password', 'POST', { email, password: pass });
    if (loginRes.status === 200) {
      console.log(`  ✅ ${email} -> Login SUCCESS (user_id: ${loginRes.data.user?.id})`);
      // Sign out
      if (loginRes.data.access_token) {
        await fetch(`${supabaseUrl}/auth/v1/logout`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${loginRes.data.access_token}`, 'apikey': serviceRoleKey }
        });
      }
    } else {
      console.log(`  ❌ ${email} -> Login FAILED: ${loginRes.data?.error_description || loginRes.data?.msg}`);
    }
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
