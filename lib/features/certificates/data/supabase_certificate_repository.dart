import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCertificateRepository implements CertificateRepository {
  final SupabaseClient _client;
  SupabaseCertificateRepository(this._client);

  @override
  Future<Result<List<CertificateModel>>> myCertificates() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return Result.err(const AuthFailure('User not authenticated.'));
      }
      final rows = await _client
          .from('certificates')
          .select('id, event_id, certificate_code, issued_at, events!event_id(title)')
          .eq('user_id', uid)
          .order('issued_at', ascending: false);
      return Result.ok((rows as List)
          .map((r) => CertificateModel(
                id: r['id'] as String,
                eventId: r['event_id'] as String,
                eventTitle: (r['events']?['title'] as String?) ?? '',
                certificateCode: r['certificate_code'] as String,
                issuedAt: DateTime.parse(r['issued_at'] as String),
              ))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> signedDownloadUrl(String certificateId) async {
    try {
      final rows = await _client
          .from('certificates')
          .select('pdf_path')
          .eq('id', certificateId);
      if ((rows as List).isEmpty) {
        return Result.err(const CertificateFailure(
            'Certificate not found or not authorized.'));
      }
      final path = rows.first['pdf_path'] as String;
      // Short-lived signed URL — the `certificates` bucket has no public
      // or authenticated-read policy, so this is the only way in.
      final url =
          await _client.storage.from('certificates').createSignedUrl(path, 300);
      return Result.ok(url);
    } catch (e) {
      return Result.err(const CertificateFailure(
          'Certificate not issued yet, or could not be downloaded.'));
    }
  }

  @override
  Future<Result<CertificateVerification>> verifyByCode(String code) async {
    try {
      final row = await _client
          .from('certificates')
          .select(
              'issued_at, events!event_id(title, start_at, clubs!club_id(name)), profiles!user_id(full_name)')
          .eq('certificate_code', code)
          .maybeSingle();
      if (row == null) {
        return Result.ok(const CertificateVerification(isValid: false));
      }
      return Result.ok(CertificateVerification(
        isValid: true,
        studentName: row['profiles']?['full_name'] as String?,
        eventName: row['events']?['title'] as String?,
        organizerName: row['events']?['clubs']?['name'] as String?,
        eventDate: row['events']?['start_at'] != null
            ? DateTime.parse(row['events']['start_at'] as String)
            : null,
      ));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }
}
