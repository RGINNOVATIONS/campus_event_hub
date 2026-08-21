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
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return const NetworkFailure();
  }
  if (text.contains('AuthApiException') || text.contains('AuthException')) {
    return AuthFailure(_friendlyAuthMessage(text), error);
  }
  if (text.contains('permission denied') || text.contains('RLS')) {
    return const AuthorizationFailure();
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
