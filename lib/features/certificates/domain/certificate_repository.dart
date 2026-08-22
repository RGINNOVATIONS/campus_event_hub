import 'package:campus_event_hub/core/result/result.dart';

class CertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String certificateCode;
  final DateTime issuedAt;
  const CertificateModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.certificateCode,
    required this.issuedAt,
  });
}

class CertificateVerification {
  final bool isValid;
  final String? studentName;
  final String? eventName;
  final String? organizerName;
  final DateTime? eventDate;
  const CertificateVerification({
    required this.isValid,
    this.studentName,
    this.eventName,
    this.organizerName,
    this.eventDate,
  });
}

abstract class CertificateRepository {
  Future<Result<List<CertificateModel>>> myCertificates();

  /// Returns a short-lived signed URL for downloading the given certificate.
  Future<Result<String>> signedDownloadUrl(String certificateId);

  Future<Result<CertificateVerification>> verifyByCode(String code);
}
