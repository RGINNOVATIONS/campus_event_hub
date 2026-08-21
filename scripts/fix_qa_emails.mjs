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
const projectRef = 'hwqfmzospluqdnadmhdg';

// Use Management API with access token
const managementToken = process.env.SUPABASE_ACCESS_TOKEN;

async function authAdminFetch(path, method = 'GET', body = null) {
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
  catch(e) { return { status: res.status, data: text }; }
}

// Test with a simple signUp with email confirm
async function createAndConfirmUser(email, password, fullName) {
  console.log(`\nProcessing ${email}...`);
  
  // Step 1: Try sign up
  const signupRes = await authAdminFetch('/admin/users', 'POST', {
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName }
  });
  
  if (signupRes.status === 200 || signupRes.status === 201) {
    console.log(`  ✅ Created and confirmed: ${email} (ID: ${signupRes.data.id})`);
    return signupRes.data.id;
  } else if (signupRes.data?.code === 422 || JSON.stringify(signupRes.data).includes('already')) {
    console.log(`  User already exists, looking up...`);
    return null;
  } else {
    console.error(`  ❌ Create error ${signupRes.status}:`, JSON.stringify(signupRes.data).substring(0, 200));
    return null;
  }
}

// Alternative: use signUp (not admin) + OTP confirm
async function signUpAndGenerateOTP(email, password) {
  const res = await fetch(`${supabaseUrl}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password, data: {} })
  });
  return { status: res.status, data: await res.json() };
}

async function main() {
  const creds = JSON.parse(fs.readFileSync('qa_credentials.json', 'utf8'));
  
  console.log('\n=== Attempting Admin User Creation via Admin API ===');
  console.log('Testing API connectivity...');
  
  // Test basic connectivity
  const testRes = await authAdminFetch('/health');
  console.log('Auth health check:', testRes.status, testRes.data);
  
  if (testRes.status !== 200) {
    console.log('\nAdmin API unreachable. Trying alternative: generate_link for email confirmation...');
    
    // Use generate_link to create magic link to confirm emails
    for (const [email, pass] of Object.entries(creds)) {
      const linkRes = await authAdminFetch('/admin/generate_link', 'POST', {
        type: 'signup',
        email,
        password: pass,
        options: { data: {} }
      });
      console.log(`${email} generate_link:`, linkRes.status, JSON.stringify(linkRes.data).substring(0, 200));
    }
    
    // Try to create admin via signup endpoint (direct)
    const adminEmail = 'xyz@nmims.edu';
    const adminPass = 'QaAdmin2024A1!';
    console.log('\nTrying direct signup for admin...');
    const r = await signUpAndGenerateOTP(adminEmail, adminPass);
    console.log('Admin signup result:', r.status, JSON.stringify(r.data).substring(0, 200));
    if (!creds[adminEmail] && r.data?.user) {
      creds[adminEmail] = adminPass;
      fs.writeFileSync('qa_credentials.json', JSON.stringify(creds, null, 2));
      console.log('Admin credentials saved.');
    }
    
  } else {
    // Admin API is working - confirm all emails
    for (const [email, pass] of Object.entries(creds)) {
      // Get user ID
      const listRes = await authAdminFetch(`/admin/users?email=${encodeURIComponent(email)}`);
      console.log(`User lookup ${email}:`, listRes.status);
      if (listRes.status === 200 && listRes.data?.users?.length > 0) {
        const user = listRes.data.users[0];
        if (!user.email_confirmed_at) {
          const upd = await authAdminFetch(`/admin/users/${user.id}`, 'PUT', { email_confirm: true });
          console.log(`  Confirm ${email}:`, upd.status);
        } else {
          console.log(`  ${email} already confirmed`);
        }
      }
    }
  }
  
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
