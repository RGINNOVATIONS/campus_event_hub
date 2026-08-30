import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/admin/presentation/screens/admin_shell.dart';
import 'package:campus_event_hub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_event_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_event_hub/features/auth/presentation/screens/register_screen.dart';
import 'package:campus_event_hub/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:campus_event_hub/features/certificates/presentation/screens/certificate_verify_screen.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/club_details_screen.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/clubs_screen.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/notification_preferences_screen.dart';
import 'package:campus_event_hub/features/enrolments/presentation/screens/qr_pass_screen.dart';
import 'package:campus_event_hub/features/events/presentation/screens/event_details_screen.dart';
import 'package:campus_event_hub/features/notifications/presentation/screens/notification_centre_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_shell.dart';
import 'package:campus_event_hub/features/profile/presentation/screens/profile_screen.dart';
import 'package:campus_event_hub/features/student/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _ProfileRefreshListenable(ref),
    redirect: (context, state) {
      final profileAsync = ref.read(currentProfileProvider);
      final profile = profileAsync.valueOrNull;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isPublicRoute = loggingIn ||
          state.matchedLocation.startsWith('/verify-certificate');

      if (profile == null) {
        if (isPublicRoute) return null;
        return '/login';
      }

      if (loggingIn) return _homeFor(profile.role);

      // Role guard: a student cannot reach organizer/admin shells and
      // vice versa (the server-side RLS/RPC checks are the real guard —
      // this just avoids showing the wrong navigation shell).
      if (state.matchedLocation.startsWith('/organizer') &&
          !(profile.role == UserRole.organizer ||
              profile.role == UserRole.admin)) {
        return _homeFor(profile.role);
      }
      if (state.matchedLocation.startsWith('/admin') &&
          profile.role != UserRole.admin) {
        return _homeFor(profile.role);
      }

      // Prevent non-students from entering the student shell or student-only screens
      if (state.matchedLocation.startsWith('/student') &&
          !state.matchedLocation.startsWith('/student/clubs') &&
          profile.role != UserRole.student) {
        return _homeFor(profile.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(
        path: '/verify-certificate',
        builder: (context, state) => CertificateVerifyScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) =>
            EventDetailsScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clubs',
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: '/clubs/:id',
        builder: (context, state) =>
            ClubDetailsScreen(clubId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/student', builder: (context, state) => const StudentShell()),
      GoRoute(
        path: '/student/notifications',
        builder: (context, state) => const NotificationCentreScreen(),
      ),
      GoRoute(
        path: '/student/my-events/:id/qr',
        builder: (context, state) =>
            QrPassScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/student/clubs',
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: '/student/clubs/:id',
        builder: (context, state) =>
            ClubDetailsScreen(clubId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/student/notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
          path: '/organizer',
          builder: (context, state) => const OrganizerShell()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
    ],
  );
});

String _homeFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return '/student';
    case UserRole.organizer:
      return '/organizer';
    case UserRole.admin:
      return '/admin';
  }
}

/// Lets go_router re-run its `redirect` whenever the auth/profile stream
/// emits, without needing a StatefulWidget wrapper around the whole app.
class _ProfileRefreshListenable extends ChangeNotifier {
  _ProfileRefreshListenable(Ref ref) {
    ref.listen(currentProfileProvider, (_, __) => notifyListeners());
  }
}
