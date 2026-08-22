import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';

void main() {
  final domains = ['nmims.edu.in', 'campus.ac.in'];

  group('CollegeEmailValidator', () {
    test('accepts a well-formed allowed-domain email', () {
      expect(CollegeEmailValidator.validate('gurjot@nmims.edu.in', domains),
          isNull);
    });

    test('rejects malformed email', () {
      expect(
          CollegeEmailValidator.validate('not-an-email', domains), isNotNull);
    });

    test('rejects a disallowed domain', () {
      expect(CollegeEmailValidator.validate('someone@gmail.com', domains),
          isNotNull);
    });

    test('is case-insensitive on domain match', () {
      expect(CollegeEmailValidator.isAllowedDomain('a@NMIMS.EDU.IN', domains),
          isTrue);
    });

    test('empty email is rejected with a clear message', () {
      expect(CollegeEmailValidator.validate('', domains),
          'College email is required.');
    });
  });
}

// NOTE: the tests above cover the CLIENT-SIDE pre-check only
// (CollegeEmailValidator, used by the registration form for fast
// feedback). That check is not the enforcement boundary — see
// supabase/migrations/20260802000001_enforce_email_domain_on_signup.sql,
// which was added after an audit found the original handle_new_user()
// trigger never consulted allowed_email_domains at all, meaning a
// direct supabase.auth.signUp() call (bypassing this Flutter app
// entirely) could previously register with any domain. The server-side
// fix can't be unit-tested here (needs a live Postgres instance — see
// TASKS.md section 0); see supabase/verification_queries.sql query #9
// for the manual verification procedure against a real project.
