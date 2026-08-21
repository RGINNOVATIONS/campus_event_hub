import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

const envPath = path.resolve('.env');
if (!fs.existsSync(envPath)) {
  console.error('Error: .env file not found.');
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
  const parts = line.split('=');
  if (parts.length >= 2) {
    envVars[parts[0].trim()] = parts.slice(1).join('=').trim();
  }
});

const supabaseUrl = envVars['SUPABASE_URL'];
const supabaseAnonKey = envVars['SUPABASE_ANON_KEY'];

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing URL or Key');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

function generatePassword() {
  return crypto.randomBytes(12).toString('base64').replace(/[^a-zA-Z0-9]/g, '') + 'A1!';
}

async function main() {
  const accounts = [
    { email: 'gurjot.singh2@nmims.in', role: 'student', name: 'QA Student' },
    { email: 'swapnil.mahajan@nmims.edu', role: 'organizer', name: 'QA Organizer' },
    { email: 'xyz@nmims.edu', role: 'admin', name: 'QA Admin' }
  ];

  const credentials = {};

  for (const acc of accounts) {
    const password = generatePassword();
    console.log(`Creating user ${acc.email}...`);
    
    const { data, error } = await supabase.auth.signUp({
      email: acc.email,
      password: password,
      options: {
        data: {
          full_name: acc.name
        }
      }
    });

    if (error) {
      if (error.message.includes('User already registered')) {
        console.log(`User ${acc.email} already exists.`);
      } else {
        console.error(`Auth Error for ${acc.email}:`, error.message);
      }
    } else if (data?.user) {
      credentials[acc.email] = password;
      console.log(`Created ${acc.email} successfully. ID: ${data.user.id}`);
    }
  }

  if (Object.keys(credentials).length > 0) {
    fs.writeFileSync('qa_credentials.json', JSON.stringify(credentials, null, 2));
    console.log('Saved credentials to qa_credentials.json');
  }

  const sql = `
UPDATE public.profiles SET role = 'organizer' WHERE id IN (SELECT id FROM auth.users WHERE email = 'swapnil.mahajan@nmims.edu');
UPDATE public.profiles SET role = 'admin' WHERE id IN (SELECT id FROM auth.users WHERE email = 'xyz@nmims.edu');
`;
  fs.writeFileSync('update_qa_roles.sql', sql);
  
  process.exit(0);
}

main();
