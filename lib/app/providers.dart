import 'package:campus_pulse/app/env.dart';
import 'package:campus_pulse/core/services/calendar_service.dart';
import 'package:campus_pulse/core/services/demo_device_token_repository.dart';
import 'package:campus_pulse/core/services/demo_notification_service.dart';
import 'package:campus_pulse/core/services/device_token_repository.dart';
import 'package:campus_pulse/core/services/firebase_notification_service.dart';
import 'package:campus_pulse/core/services/notification_service.dart';
import 'package:campus_pulse/core/services/supabase_device_token_repository.dart';
import 'package:campus_pulse/features/admin/data/demo_admin_repository.dart';
import 'package:campus_pulse/features/admin/data/supabase_admin_repository.dart';
import 'package:campus_pulse/features/admin/domain/admin_repository.dart';
import 'package:campus_pulse/features/auth/data/demo_auth_repository.dart';
import 'package:campus_pulse/features/auth/data/supabase_auth_repository.dart';
import 'package:campus_pulse/features/auth/domain/auth_repository.dart';
import 'package:campus_pulse/features/auth/domain/profile.dart';
import 'package:campus_pulse/features/certificates/data/demo_certificate_repository.dart';
import 'package:campus_pulse/features/certificates/data/supabase_certificate_repository.dart';
import 'package:campus_pulse/features/certificates/domain/certificate_repository.dart';
import 'package:campus_pulse/features/clubs/data/demo_club_repository.dart';
import 'package:campus_pulse/features/clubs/data/supabase_club_repository.dart';
import 'package:campus_pulse/features/clubs/domain/club_repository.dart';
import 'package:campus_pulse/features/events/data/demo_event_repository.dart';
import 'package:campus_pulse/features/events/data/supabase_event_repository.dart';
import 'package:campus_pulse/features/events/domain/event_repository.dart';
import 'package:campus_pulse/features/notifications/data/demo_notification_repository.dart';
import 'package:campus_pulse/features/notifications/data/supabase_notification_repository.dart';
import 'package:campus_pulse/features/notifications/domain/notification_repository.dart';
import 'package:campus_pulse/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_pulse/features/organizer/data/supabase_organizer_repository.dart';
import 'package:campus_pulse/features/organizer/domain/organizer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True whenever the app should use in-memory demo repositories instead
/// of talking to Supabase. Driven by Env (APP_DEMO_MODE / missing creds).
final demoModeProvider = Provider<bool>((ref) => Env.isDemoMode);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoAuthRepository();
  return SupabaseAuthRepository(Supabase.instance.client);
});

final currentProfileProvider = StreamProvider<Profile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchCurrentProfile();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoEventRepository();
  return SupabaseEventRepository(Supabase.instance.client);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoNotificationRepository();
  return SupabaseNotificationRepository(Supabase.instance.client);
});

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoCertificateRepository();
  return SupabaseCertificateRepository(Supabase.instance.client);
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoOrganizerRepository();
  return SupabaseOrganizerRepository(Supabase.instance.client);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoAdminRepository();
  return SupabaseAdminRepository(Supabase.instance.client);
});

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoClubRepository();
  return SupabaseClubRepository(Supabase.instance.client);
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  if (ref.watch(demoModeProvider)) return DemoDeviceTokenRepository();
  return SupabaseDeviceTokenRepository(Supabase.instance.client);
});

/// Kept as a single instance for the app's lifetime (not `autoDispose`)
/// so its internal token-refresh/tap listeners stay alive for the whole
/// session rather than being torn down between screen rebuilds.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final tokenRepo = ref.watch(deviceTokenRepositoryProvider);
  String? currentUserId() =>
      ref.read(authRepositoryProvider).currentProfile?.id;
  if (ref.watch(demoModeProvider)) {
    return DemoNotificationService(
        tokenRepository: tokenRepo, currentUserId: currentUserId);
  }
  return FirebaseNotificationService(
      tokenRepository: tokenRepo, currentUserId: currentUserId);
});

final calendarServiceProvider =
    Provider<CalendarService>((ref) => CalendarService());
