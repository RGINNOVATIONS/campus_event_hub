import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:supabase/supabase.dart';

String generatePassword() {
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
  Random rnd = Random.secure();
  return String.fromCharCodes(Iterable.generate(16, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

void main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('Error: .env file not found.');
    exit(1);
  }

  final envVars = <String, String>{};
  for (final line in await envFile.readAsLines()) {
    final parts = line.split('=');
    if (parts.length >= 2) {
      envVars[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final supabaseUrl = envVars['SUPABASE_URL'];
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY missing from .env');
    exit(1);
  }

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final accounts = [
    {'email': 'gurjot.singh2@nmims.in', 'role': 'student', 'name': 'QA Student'},
    {'email': 'swapnil.mahajan@nmims.edu', 'role': 'organizer', 'name': 'QA Organizer'},
    {'email': 'xyz@nmims.edu', 'role': 'admin', 'name': 'QA Admin'}
  ];

  final credentials = <String, String>{};

  for (var acc in accounts) {
    final email = acc['email']!;
    final password = generatePassword();
    
    try {
      print('Creating user $email...');
      final response = await client.auth.signUp(
        email: email, 
        password: password,
        data: {'full_name': acc['name']}
      );
      
      if (response.user != null) {
        credentials[email] = password;
        print('Created $email successfully.');
      }
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        print('User $email already exists, skipping creation but you must handle password manually.');
      } else {
        print('Auth Error for $email: ${e.message}');
      }
    } catch (e) {
      print('Error for $email: $e');
    }
  }

  if (credentials.isNotEmpty) {
    final credFile = File('qa_credentials.json');
    await credFile.writeAsString(jsonEncode(credentials));
    print('Saved credentials to qa_credentials.json');
  }

  // Also create a temp sql file to update roles easily via npx supabase db query
  final sqlFile = File('update_qa_roles.sql');
  await sqlFile.writeAsString('''
UPDATE public.profiles SET role = 'organizer' WHERE id IN (SELECT id FROM auth.users WHERE email = 'swapnil.mahajan@nmims.edu');
UPDATE public.profiles SET role = 'admin' WHERE id IN (SELECT id FROM auth.users WHERE email = 'xyz@nmims.edu');
  ''');
  
  exit(0);
}
