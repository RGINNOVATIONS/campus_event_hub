import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/features/events/domain/event.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  group('EventDateValidator', () {
    test('valid dates pass', () {
      final result = EventDateValidator.validate(
        start: DateTime(2026, 9, 1, 10),
        end: DateTime(2026, 9, 1, 12),
        registrationDeadline: DateTime(2026, 8, 30),
        now: now,
      );
      expect(result, isNull);
    });

    test('start in the past is rejected', () {
      final result = EventDateValidator.validate(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 2),
        registrationDeadline: DateTime(2025, 12, 30),
        now: now,
      );
      expect(result, isNotNull);
    });

    test('end before start is rejected', () {
      final result = EventDateValidator.validate(
        start: DateTime(2026, 9, 2),
        end: DateTime(2026, 9, 1),
        registrationDeadline: DateTime(2026, 8, 30),
        now: now,
      );
      expect(result, contains('End time'));
    });

    test('registration deadline after start is rejected', () {
      final result = EventDateValidator.validate(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 2),
        registrationDeadline: DateTime(2026, 9, 1, 12),
        now: now,
      );
      expect(result, contains('Registration deadline'));
    });
  });
}
