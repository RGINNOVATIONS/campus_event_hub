import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const envContent = fs.readFileSync(path.resolve('.env'), 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
});

// Use service role key - read from env if present, otherwise prompt
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!serviceRoleKey) {
  console.error('ERROR: SUPABASE_SERVICE_ROLE_KEY env var not set.');
  console.error('Run as: SUPABASE_SERVICE_ROLE_KEY=<your-key> node scripts/confirm_qa_emails.mjs');
  process.exit(1);
}

const adminClient = createClient(envVars['SUPABASE_URL'], serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

const accounts = [
  'gurjot.singh2@nmims.in',
  'swapnil.mahajan@nmims.edu',
  'xyz@nmims.edu'
];

async function main() {
  const credentials = JSON.parse(fs.readFileSync('qa_credentials.json', 'utf8'));

  // Create admin account first if missing
  if (!credentials['xyz@nmims.edu']) {
    console.log('Creating admin user via admin API...');
    const { data, error } = await adminClient.auth.admin.createUser({
      email: 'xyz@nmims.edu',
      password: 'QaAdmin2024A1!',
      email_confirm: true,
      user_metadata: { full_name: 'QA Admin' }
    });
    if (error) {
      console.error('Admin create error:', error.message);
    } else {
      credentials['xyz@nmims.edu'] = 'QaAdmin2024A1!';
      console.log('Admin created. ID:', data.user.id);
    }
  }

  // Confirm emails for all accounts
  for (const email of accounts) {
    console.log(`\nConfirming email for ${email}...`);
    const { data: listData, error: listError } = await adminClient.auth.admin.listUsers();
    if (listError) { console.error('List error:', listError.message); continue; }
    
    const user = listData?.users?.find(u => u.email === email);
    if (!user) { console.log(`User ${email} not found.`); continue; }
    
    if (!user.email_confirmed_at) {
      const { error: updateError } = await adminClient.auth.admin.updateUserById(user.id, {
        email_confirm: true
      });
      if (updateError) {
        console.error(`  Confirm error for ${email}:`, updateError.message);
      } else {
        console.log(`  Email confirmed for ${email}`);
      }
    } else {
      console.log(`  Already confirmed for ${email}`);
    }
  }

  // Update roles using admin API to bypass RLS trigger
  console.log('\nUpdating roles...');
  const { data: listData2 } = await adminClient.auth.admin.listUsers();
  const users = listData2?.users || [];

  for (const user of users) {
    let newRole = null;
    if (user.email === 'swapnil.mahajan@nmims.edu') newRole = 'organizer';
    if (user.email === 'xyz@nmims.edu') newRole = 'admin';
    if (!newRole) continue;

    // Update profile role directly via service role (bypasses anon RLS)
    const { error } = await adminClient.from('profiles').update({ role: newRole }).eq('id', user.id);
    if (error) {
      console.error(`  Role update error for ${user.email}:`, error.message);
    } else {
      console.log(`  Role set to ${newRole} for ${user.email}`);
    }
  }

  // Save updated credentials
  fs.writeFileSync('qa_credentials.json', JSON.stringify(credentials, null, 2));

  // Final verification
  console.log('\n=== Final Profile Verification ===');
  const { data: profiles, error: pErr } = await adminClient.from('profiles').select('college_email, role, full_name');
  if (pErr) {
    console.error('Profile query error:', pErr.message);
  } else {
    console.log('Profiles:', JSON.stringify(profiles, null, 2));
  }

  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
