import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for sharing documents via Bluetooth, social media, or other apps.
class ShareService {
  const ShareService();

  /// Shares a PDF via the native system share sheet (Bluetooth, WhatsApp, Telegram, etc.).
  ///
  /// Prefers [localPath] in internal storage when available so no extra copy is needed.
  Future<bool> shareAssetPdf({
    required String assetPath,
    String? localPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) async {
    try {
      String shareFilePath;
      if (!kIsWeb &&
          localPath != null &&
          localPath.isNotEmpty &&
          await File(localPath).exists()) {
        shareFilePath = localPath;
      } else {
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}${Platform.pathSeparator}$fileName',
        );
        await tempFile.writeAsBytes(bytes, flush: true);
        shareFilePath = tempFile.path;
      }

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              shareFilePath,
              mimeType: 'application/pdf',
              name: fileName,
            ),
          ],
          subject: subject,
          text: text,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}
