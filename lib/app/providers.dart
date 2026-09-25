import 'package:campus_event_hub/core/services/calendar_service.dart';
import 'package:campus_event_hub/core/services/device_token_repository.dart';
import 'package:campus_event_hub/core/services/download_service.dart';
import 'package:campus_event_hub/core/services/firebase_notification_service.dart';
import 'package:campus_event_hub/core/services/notification_service.dart';
import 'package:campus_event_hub/core/services/supabase_device_token_repository.dart';
import 'package:campus_event_hub/features/admin/data/supabase_admin_repository.dart';
import 'package:campus_event_hub/features/admin/domain/admin_repository.dart';
import 'package:campus_event_hub/features/auth/data/supabase_auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';
import 'package:campus_event_hub/features/certificates/data/supabase_certificate_repository.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:campus_event_hub/features/clubs/data/supabase_club_repository.dart';
import 'package:campus_event_hub/features/clubs/domain/club_repository.dart';
import 'package:campus_event_hub/features/events/data/supabase_event_repository.dart';
import 'package:campus_event_hub/features/events/domain/event_repository.dart';
import 'package:campus_event_hub/features/notifications/data/supabase_notification_repository.dart';
import 'package:campus_event_hub/features/notifications/domain/notification_repository.dart';
import 'package:campus_event_hub/features/organizer/data/supabase_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/reports/data/report_ai_service.dart';
import 'package:campus_event_hub/features/reviews/data/supabase_review_repository.dart';
import 'package:campus_event_hub/features/reviews/domain/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

final currentProfileProvider = StreamProvider<Profile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchCurrentProfile();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return SupabaseEventRepository(Supabase.instance.client);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return SupabaseCertificateRepository(Supabase.instance.client);
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return SupabaseOrganizerRepository(Supabase.instance.client);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(Supabase.instance.client);
});

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return SupabaseClubRepository(Supabase.instance.client);
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return SupabaseDeviceTokenRepository(Supabase.instance.client);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(Supabase.instance.client);
});

final reportAiServiceProvider = Provider<ReportAiService>((ref) {
  return SupabaseReportAiService(Supabase.instance.client);
});

/// Kept as a single instance for the app's lifetime (not `autoDispose`)
/// so its internal token-refresh/tap listeners stay alive for the whole
/// session rather than being torn down between screen rebuilds.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final tokenRepo = ref.watch(deviceTokenRepositoryProvider);
  String? currentUserId() =>
      ref.read(authRepositoryProvider).currentProfile?.id;
  return FirebaseNotificationService(
      tokenRepository: tokenRepo, currentUserId: currentUserId);
});

final calendarServiceProvider =
    Provider<CalendarService>((ref) => CalendarService());

final downloadServiceProvider =
    Provider<DownloadService>((ref) => const DefaultDownloadService());
