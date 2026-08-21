import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const envContent = fs.readFileSync(path.resolve('.env'), 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

const supabase = createClient(envVars['SUPABASE_URL'], envVars['SUPABASE_ANON_KEY']);

async function main() {
  console.log('\n=== Step 1: Verify Admin Account Status ===');
  // Try to sign in with the admin email using same password as organizer (same hash was used in SQL insert)
  const adminEmail = 'xyz@nmims.edu';
  const adminPass = 'kzbJb6uOuSdoAkqA1!';

  // Check if admin needs to be re-created (rate limit may have passed)
  const credentials = JSON.parse(fs.readFileSync('qa_credentials.json', 'utf8'));
  if (!credentials[adminEmail]) {
    console.log('Admin not in credentials - attempting to create now (rate limit may have cleared)...');
    const { data, error } = await supabase.auth.signUp({
      email: adminEmail,
      password: adminPass,
      options: { data: { full_name: 'QA Admin' } }
    });
    if (error) {
      console.error('Admin signup error:', error.message);
    } else if (data?.user) {
      credentials[adminEmail] = adminPass;
      fs.writeFileSync('qa_credentials.json', JSON.stringify(credentials, null, 2));
      console.log('Admin created successfully. ID:', data.user.id);
    }
  } else {
    console.log('Admin already in credentials file.');
  }

  console.log('\n=== Step 2: Verify profiles table via anon key (own profile check) ===');
  
  // Sign in as student to verify profile
  const studentLogin = await supabase.auth.signInWithPassword({
    email: 'gurjot.singh2@nmims.in',
    password: credentials['gurjot.singh2@nmims.in']
  });
  if (studentLogin.error) {
    console.log('Student login error:', studentLogin.error.message);
  } else {
    const { data: profile } = await supabase.from('profiles').select('college_email, role, full_name').eq('id', studentLogin.data.user.id).single();
    console.log('Student profile:', profile);
    await supabase.auth.signOut();
  }

  // Sign in as organizer
  const orgLogin = await supabase.auth.signInWithPassword({
    email: 'swapnil.mahajan@nmims.edu',
    password: credentials['swapnil.mahajan@nmims.edu']
  });
  if (orgLogin.error) {
    console.log('Organizer login error:', orgLogin.error.message);
  } else {
    const { data: profile } = await supabase.from('profiles').select('college_email, role, full_name').eq('id', orgLogin.data.user.id).single();
    console.log('Organizer profile:', profile);
    await supabase.auth.signOut();
  }

  // Sign in as admin
  const adminPass2 = credentials[adminEmail];
  if (adminPass2) {
    const adminLogin = await supabase.auth.signInWithPassword({
      email: adminEmail,
      password: adminPass2
    });
    if (adminLogin.error) {
      console.log('Admin login error:', adminLogin.error.message);
    } else {
      const { data: profile } = await supabase.from('profiles').select('college_email, role, full_name').eq('id', adminLogin.data.user.id).single();
      console.log('Admin profile:', profile);
      await supabase.auth.signOut();
    }
  }

  console.log('\n=== Step 3: Check allowed_email_domains ===');
  const { data: domains } = await supabase.from('allowed_email_domains').select('domain, is_active');
  console.log('Allowed domains:', domains);
  
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
