import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapExceptionToFailure PostgrestException mapping', () {
    test('duplicate enrollment error code 23505 maps to ValidationFailure with friendly message', () {
      final exception = PostgrestException(
        message: 'duplicate key value violates unique constraint "enrolments_event_id_user_id_key"',
        code: '23505',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'You are already enrolled in this event.');
    });

    test('already enrolled message maps to ValidationFailure with friendly message', () {
      final exception = PostgrestException(
        message: 'You are already enrolled in this event.',
        code: 'P0001',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'You are already enrolled in this event.');
    });

    test('registration closed message maps to ValidationFailure', () {
      final exception = PostgrestException(
        message: 'Registration for this event has closed.',
        code: 'P0001',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Registration for this event has closed.');
    });

    test('event not open message maps to ValidationFailure', () {
      final exception = PostgrestException(
        message: 'This event is not open for registration.',
        code: 'P0001',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'This event is not open for registration.');
    });

    test('event already started message maps to ValidationFailure', () {
      final exception = PostgrestException(
        message: 'This event has already started.',
        code: 'P0001',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'This event has already started.');
    });

    test('event not found message maps to ValidationFailure', () {
      final exception = PostgrestException(
        message: 'Event not found.',
        code: 'P0001',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Event not found.');
    });

    test('RLS permission denied code 42501 maps to AuthorizationFailure', () {
      final exception = PostgrestException(
        message: 'permission denied for table enrolments',
        code: '42501',
      );
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<AuthorizationFailure>());
    });

    test('generic unknown exception falls back to custom fallback message', () {
      final exception = Exception('Something unpredicted');
      final failure = mapExceptionToFailure(exception, fallbackMessage: 'Could not enrol in this event.');
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Could not enrol in this event.');
    });
  });
}
