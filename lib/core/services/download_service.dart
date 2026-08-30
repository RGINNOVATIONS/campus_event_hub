import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Downloads or saves a file and opens it, in a way that works on mobile/desktop
/// (`path_provider` + `open_filex`) and Flutter Web (browser download/open).
abstract class DownloadService {
  /// Downloads [url] (expected to be a short-lived signed URL) and opens
  /// it with the platform's default handler. Returns true on success.
  Future<bool> downloadAndOpen({
    required String url,
    required String suggestedFileName,
  });

  /// Saves [csvContent] as a file and opens or triggers browser download for it.
  Future<bool> saveAndOpenCsv({
    required String csvContent,
    required String fileName,
  });
}

class DefaultDownloadService implements DownloadService {
  const DefaultDownloadService();

  @override
  Future<bool> downloadAndOpen({
    required String url,
    required String suggestedFileName,
  }) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[DownloadService] error opening URL: $e');
      return false;
    }
  }

  @override
  Future<bool> saveAndOpenCsv({
    required String csvContent,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        final uri = Uri.dataFromString(
          csvContent,
          mimeType: 'text/csv',
          encoding: utf8,
        );
        return await launchUrl(uri);
      } else {
        Directory dir;
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = await getTemporaryDirectory();
        }
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(csvContent, flush: true);
        final result = await OpenFilex.open(file.path);
        return result.type == ResultType.done ||
            result.type == ResultType.noAppToOpen;
      }
    } catch (e) {
      debugPrint('[DownloadService] error saving CSV: $e');
      return false;
    }
  }
}
