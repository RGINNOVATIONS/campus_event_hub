import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/certificates/data/demo_certificate_repository.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:campus_event_hub/features/certificates/presentation/screens/my_certificates_screen.dart';

class _EmptyCertificateRepo implements CertificateRepository {
  @override
  Future<Result<List<CertificateModel>>> myCertificates() async =>
      Result.ok([]);
  @override
  Future<Result<String>> signedDownloadUrl(String certificateId) async =>
      throw UnimplementedError();
  @override
  Future<Result<CertificateVerification>> verifyByCode(String code) async =>
      Result.ok(const CertificateVerification(isValid: false));
}

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('shows "Certificate not issued yet" when the student has none',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateRepositoryProvider
              .overrideWithValue(_EmptyCertificateRepo())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const MyCertificatesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Certificate not issued yet.'), findsOneWidget);
  });

  testWidgets('shows an issued certificate with its code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateRepositoryProvider
              .overrideWithValue(DemoCertificateRepository())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const MyCertificatesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Winter Hackathon 2025'), findsOneWidget);
    expect(find.textContaining('CP2025WH0421'), findsOneWidget);
  });
}
