/// Downloads a file from a (typically signed) URL and opens it, in a way
/// that works on both Android (path_provider + open_filex) and Flutter
/// Web (browser download). Screens call this instead of touching
/// `path_provider`/`open_filex`/`url_launcher` directly.
abstract class DownloadService {
  /// Downloads [url] (expected to be a short-lived signed URL) and opens
  /// it with the platform's default handler. Returns true on success.
  Future<bool> downloadAndOpen(
      {required String url, required String suggestedFileName});
}

/// Mobile/desktop implementation sketch (not wired into DI yet — see
/// TASKS.md): use `path_provider` to get a writable directory, stream
/// the URL to a file with `http`/`dio`, then `open_filex.open(path)`.
///
/// Web implementation sketch: `url_launcher`'s `launchUrl` with
/// `LaunchMode.externalApplication` on the signed URL is sufficient,
/// since browsers handle the download themselves — this is what
/// `MyCertificatesScreen` currently does directly rather than going
/// through this interface, which is why this file is marked partial.
