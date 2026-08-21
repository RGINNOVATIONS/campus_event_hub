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
  const adminEmail = 'xyz@nmims.edu';
  const adminPass = 'QaAdmin2024A1!';

  // Step 1: Find admin user via generate_link (tells us if corrupted record exists)
  console.log('=== Checking admin user state ===');
  const gl = await go('/admin/generate_link', 'POST', { type: 'magiclink', email: adminEmail });
  console.log(`generate_link: ${gl.status}`);
  
  if (gl.status === 500) {
    const errMsg = gl.data?.msg || '';
    if (errMsg.includes('Database error finding user')) {
      // Corrupted row in auth.users - we need to use the REST Postgres API to delete it
      // Use PostgREST with service role to delete from auth schema via a workaround:
      // Actually, use supabase rpc if available, or use the auth admin delete endpoint
      // Since we don't have the user ID, try a different approach: 
      // Use the Supabase Management API (requires Personal Access Token, not service role)
      console.log('Admin row is corrupted. Attempting delete via profiles cascade...');
      
      // Delete the profile first (cascade should clean auth.users if on delete cascade)
      const delProfile = await fetch(`${supabaseUrl}/rest/v1/profiles?college_email=eq.${encodeURIComponent(adminEmail)}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        }
      });
      const delText = await delProfile.text();
      console.log(`Profile DELETE: ${delProfile.status}`, delText);
    }
  }

  // Wait a moment then retry create
  await new Promise(r => setTimeout(r, 2000));

  console.log('\n=== Attempting admin creation again ===');
  const createRes = await go('/admin/users', 'POST', {
    email: adminEmail,
    password: adminPass,
    email_confirm: true,
    user_metadata: { full_name: 'QA Admin' }
  });
  console.log(`Create: ${createRes.status}`, JSON.stringify(createRes.data).substring(0, 300));

  if (createRes.status === 200 || createRes.status === 201) {
    console.log(`✅ Admin created. ID: ${createRes.data.id}`);
    creds[adminEmail] = adminPass;
    fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
    
    // Test login
    const loginRes = await go('/token?grant_type=password', 'POST', { email: adminEmail, password: adminPass });
    console.log(`Admin login: ${loginRes.status === 200 ? '✅ SUCCESS' : '❌ FAILED: ' + JSON.stringify(loginRes.data)}`);
    if (loginRes.status === 200 && loginRes.data.access_token) {
      await fetch(`${supabaseUrl}/auth/v1/logout`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${loginRes.data.access_token}`, 'apikey': serviceRoleKey }
      });
    }
  }

  // Final summary
  console.log('\n=== All Account Login Status ===');
  const allCreds = JSON.parse(fs.readFileSync('qa_credentials.json', 'utf8'));
  for (const [email, pass] of Object.entries(allCreds)) {
    const r = await go('/token?grant_type=password', 'POST', { email, password: pass });
    const ok = r.status === 200;
    console.log(`  ${ok ? '✅' : '❌'} ${email}: ${ok ? 'LOGIN OK (id=' + r.data.user?.id + ')' : r.data?.error_description || r.data?.msg}`);
    if (ok && r.data.access_token) {
      await fetch(`${supabaseUrl}/auth/v1/logout`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${r.data.access_token}`, 'apikey': serviceRoleKey }
      });
    }
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
