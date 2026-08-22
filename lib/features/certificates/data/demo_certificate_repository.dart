import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:campus_event_hub/core/result/result.dart';

class DemoCertificateRepository implements CertificateRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-student-1';

  @override
  Future<Result<List<CertificateModel>>> myCertificates() async =>
      Result.ok([...(_store.certificatesByUser[_uid] ?? [])]);

  @override
  Future<Result<String>> signedDownloadUrl(String certificateId) async {
    // In demo mode there is no real file; a local demo PDF is bundled
    // under assets/demo/ and opened directly by the download service.
    return Result.ok('demo://assets/demo/sample_certificate.pdf');
  }

  @override
  Future<Result<CertificateVerification>> verifyByCode(String code) async {
    for (final list in _store.certificatesByUser.values) {
      for (final cert in list) {
        if (cert.certificateCode == code) {
          return Result.ok(CertificateVerification(
            isValid: true,
            studentName: 'Aisha Sharma',
            eventName: cert.eventTitle,
            organizerName: 'Robotics & Automation Club',
            eventDate: cert.issuedAt.subtract(const Duration(days: 5)),
          ));
        }
      }
    }
    return Result.ok(const CertificateVerification(isValid: false));
  }
}
