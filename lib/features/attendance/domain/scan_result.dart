enum ScanOutcome {
  success,
  alreadyCheckedIn,
  invalidToken,
  wrongEvent,
  notAuthorized,
  networkError
}

class ScanResultUi {
  final String title;
  final String message;
  final bool isSuccess;
  const ScanResultUi(this.title, this.message, this.isSuccess);
}

/// Maps a raw backend scan result (the string returned by the
/// `mark_event_attendance` Postgres function) to what the scanner screen
/// shows. Kept pure/testable per spec section 25.
class ScanResultMapper {
  ScanResultMapper._();

  static ScanOutcome fromBackendCode(String code) {
    switch (code) {
      case 'ok':
        return ScanOutcome.success;
      case 'already_checked_in':
        return ScanOutcome.alreadyCheckedIn;
      case 'invalid_token':
        return ScanOutcome.invalidToken;
      case 'wrong_event':
        return ScanOutcome.wrongEvent;
      case 'not_authorized':
        return ScanOutcome.notAuthorized;
      default:
        return ScanOutcome.networkError;
    }
  }

  static ScanResultUi uiFor(ScanOutcome outcome) {
    switch (outcome) {
      case ScanOutcome.success:
        return const ScanResultUi(
            'Checked in', 'Attendance marked successfully.', true);
      case ScanOutcome.alreadyCheckedIn:
        return const ScanResultUi(
            'Already checked in', 'This student was already scanned.', false);
      case ScanOutcome.invalidToken:
        return const ScanResultUi(
            'Invalid pass', 'This QR code is not recognized.', false);
      case ScanOutcome.wrongEvent:
        return const ScanResultUi(
            'Wrong event', 'This pass belongs to a different event.', false);
      case ScanOutcome.notAuthorized:
        return const ScanResultUi(
            'Not authorized', 'You cannot scan for this event.', false);
      case ScanOutcome.networkError:
        return const ScanResultUi(
            'Scan failed', 'Could not reach the server. Try again.', false);
    }
  }
}
