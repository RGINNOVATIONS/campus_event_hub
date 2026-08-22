import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed failures so the UI can render a specific, understandable message
/// instead of a stack trace. Every repository/service maps raw exceptions
/// (PostgrestException, AuthException, SocketException, etc.) into one of
/// these before returning a [Result].
sealed class AppFailure {
  final String message;
  final Object? cause;
  const AppFailure(this.message, [this.cause]);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, [super.cause]);
}

class ValidationFailure extends AppFailure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure(
      [super.message = 'You are not allowed to do that.']);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message, [super.cause]);
}

class AttendanceFailure extends AppFailure {
  const AttendanceFailure(super.message);
}

class NotificationFailure extends AppFailure {
  const NotificationFailure(super.message, [super.cause]);
}

class CertificateFailure extends AppFailure {
  const CertificateFailure(super.message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.', super.cause]);
}

/// Maps a caught exception to a typed failure. Logs the technical detail
/// only in debug builds; never surfaces it to the user.
AppFailure mapExceptionToFailure(Object error, {String? fallbackMessage}) {
  if (kDebugMode) {
    if (error is PostgrestException) {
      debugPrint(
          '[Supabase Error] Code: ${error.code}, Message: ${error.message}, Details: ${error.details}, Hint: ${error.hint}');
    } else {
      debugPrint('[App Error] $error');
    }
  }

  final text = error.toString();
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return const NetworkFailure();
  }
  if (text.contains('AuthApiException') || text.contains('AuthException')) {
    return AuthFailure(_friendlyAuthMessage(text), error);
  }
  if (text.contains('permission denied') ||
      text.contains('RLS') ||
      (error is PostgrestException && error.code == '42501')) {
    return const AuthorizationFailure();
  }

  if (error is PostgrestException) {
    final msg = error.message;
    final code = error.code;
    if (code == '23505' ||
        msg.toLowerCase().contains('already enrolled') ||
        msg.toLowerCase().contains('already registered')) {
      return const ValidationFailure('You are already enrolled in this event.');
    }
    if (msg.toLowerCase().contains('closed') ||
        msg.toLowerCase().contains('deadline')) {
      return const ValidationFailure('Registration for this event has closed.');
    }
    if (msg.toLowerCase().contains('not open') ||
        msg.toLowerCase().contains('no longer available')) {
      return const ValidationFailure(
          'This event is not open for registration.');
    }
    if (msg.toLowerCase().contains('already started')) {
      return const ValidationFailure('This event has already started.');
    }
    if (msg.toLowerCase().contains('event not found')) {
      return const ValidationFailure('Event not found.');
    }
    if (msg.isNotEmpty &&
        !msg.startsWith('function ') &&
        !msg.contains('syntax error') &&
        !msg.contains('does not exist')) {
      return ValidationFailure(msg);
    }
  }

  return UnknownFailure(fallbackMessage ?? 'Something went wrong.', error);
}

String _friendlyAuthMessage(String raw) {
  if (raw.contains('Invalid login credentials')) {
    return 'Incorrect email or password.';
  }
  if (raw.contains('Email not confirmed')) {
    return 'Please verify your college email before signing in.';
  }
  if (raw.contains('User already registered')) {
    return 'An account with this email already exists.';
  }
  return 'Authentication failed. Please try again.';
}
