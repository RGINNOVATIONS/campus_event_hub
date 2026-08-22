import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_eligibility.dart';

void main() {
  test('attended + completed event is eligible', () {
    expect(
      CertificateEligibility.isEligible(
          eventStatus: EventStatus.completed,
          attendanceStatus: AttendanceStatus.attended),
      isTrue,
    );
  });

  test('registered but not attended is not eligible', () {
    expect(
      CertificateEligibility.isEligible(
          eventStatus: EventStatus.completed,
          attendanceStatus: AttendanceStatus.registered),
      isFalse,
    );
  });

  test('attended but event not yet completed is not eligible', () {
    expect(
      CertificateEligibility.isEligible(
          eventStatus: EventStatus.published,
          attendanceStatus: AttendanceStatus.attended),
      isFalse,
    );
  });
}
