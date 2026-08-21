/// Wraps `firebase_messaging` + `flutter_local_notifications` behind one
/// interface so screens never touch either plugin directly.
///
/// NOT device/emulator-tested in this build sandbox (no SDK, no
/// emulator) — the shape is correct and matches each plugin's documented
/// API, but treat this as unverified until run on a real device. See
/// TASKS.md section 2.
abstract class NotificationService {
  /// Call once after login. Registers the current FCM token (and
  /// re-registers on `onTokenRefresh`) into the `device_tokens` table.
  Future<void> registerDeviceToken();

  /// Call on logout. Best-effort removal of this device's token row so
  /// a signed-out device stops receiving pushes for the old account.
  Future<void> unregisterDeviceToken();

  /// Shows a local notification while the app is in the foreground
  /// (FCM does not auto-display foreground notifications on
  /// Android/iOS — this is the documented workaround).
  Future<void> showForegroundNotification(
      {required String title, required String body});

  /// Called when a push notification is tapped from the background/
  /// terminated state. Returns the `event_id` payload field, if any, so
  /// the caller can deep-link via go_router.
  Stream<String?> get onNotificationTapped;
}
