import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/features/attendance/domain/scan_result.dart';

void main() {
  group('ScanResultMapper', () {
    test('ok maps to success', () {
      expect(ScanResultMapper.fromBackendCode('ok'), ScanOutcome.success);
    });
    test('already_checked_in maps correctly and is not success', () {
      final outcome = ScanResultMapper.fromBackendCode('already_checked_in');
      expect(outcome, ScanOutcome.alreadyCheckedIn);
      expect(ScanResultMapper.uiFor(outcome).isSuccess, isFalse);
    });
    test('unknown code falls back to networkError', () {
      expect(ScanResultMapper.fromBackendCode('garbage'),
          ScanOutcome.networkError);
    });
    test('success ui is marked success', () {
      expect(ScanResultMapper.uiFor(ScanOutcome.success).isSuccess, isTrue);
    });
  });
}
