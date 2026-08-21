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

  console.log('=== Looking up admin via generate_link ===');
  // generate_link works for existing users
  const gl = await go('/admin/generate_link', 'POST', { type: 'magiclink', email: adminEmail });
  console.log(`generate_link status: ${gl.status}`);
  
  if (gl.status === 200) {
    const adminId = gl.data.id;
    console.log(`Admin exists. ID: ${adminId}`);
    console.log(`email_confirmed_at: ${gl.data.email_confirmed_at || 'NOT CONFIRMED'}`);
    
    // Confirm email
    if (!gl.data.email_confirmed_at) {
      console.log('Confirming admin email...');
      const conf = await go(`/admin/users/${adminId}`, 'PUT', { email_confirm: true });
      console.log(`Confirm result: ${conf.status}`, conf.status === 200 ? `✅ confirmed_at: ${conf.data.email_confirmed_at}` : JSON.stringify(conf.data).substring(0,200));
    }
    
    // Update password to something we know
    console.log('Resetting admin password...');
    const passUpdate = await go(`/admin/users/${adminId}`, 'PUT', { password: adminPass });
    console.log(`Password update: ${passUpdate.status}`);
    
    // Test login
    console.log('Testing admin login...');
    const loginRes = await go('/token?grant_type=password', 'POST', { email: adminEmail, password: adminPass });
    if (loginRes.status === 200) {
      console.log(`✅ Admin login SUCCESS. user_id: ${loginRes.data.user?.id}`);
      creds[adminEmail] = adminPass;
      fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
    } else {
      console.log(`❌ Admin login FAILED: ${JSON.stringify(loginRes.data)}`);
    }
    
  } else {
    console.log('Admin not found via generate_link:', JSON.stringify(gl.data));
    
    // The SQL insert may have created a user with a conflicting password hash
    // Try to sign in with organizer's password (same hash was used in insert)
    console.log('\nTrying organizer password for admin...');
    const orgPass = creds['swapnil.mahajan@nmims.edu'];
    const tryLogin = await go('/token?grant_type=password', 'POST', { email: adminEmail, password: orgPass });
    console.log(`Login with organizer pass: ${tryLogin.status}`, tryLogin.status === 200 ? '✅' : JSON.stringify(tryLogin.data));
    if (tryLogin.status === 200) {
      creds[adminEmail] = orgPass;
      fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
    }
  }
  
  // Final credential summary (no passwords)
  console.log('\n=== Final Credential Summary ===');
  for (const [email] of Object.entries(creds)) {
    const loginRes = await go('/token?grant_type=password', 'POST', { email, password: creds[email] });
    const status = loginRes.status === 200 ? '✅ LOGIN OK' : `❌ FAIL: ${loginRes.data?.error_description || loginRes.data?.msg}`;
    console.log(`  ${email}: ${status}`);
    if (loginRes.status === 200 && loginRes.data.access_token) {
      await fetch(`${supabaseUrl}/auth/v1/logout`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${loginRes.data.access_token}`, 'apikey': serviceRoleKey }
      });
    }
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
