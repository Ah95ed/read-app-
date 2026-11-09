import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for sharing documents via Bluetooth, social media, or other apps
class ShareService {
  const ShareService();

  /// Shares a PDF asset via the native system share sheet (Bluetooth, WhatsApp, Telegram, etc.)
  Future<bool> shareAssetPdf({
    required String assetPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Load bytes from asset
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Write to temp directory so external apps can access the file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes, flush: true);

      // Trigger system share via updated SharePlus API
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              tempFile.path,
              mimeType: 'application/pdf',
              name: fileName,
            ),
          ],
          subject: subject,
          text: text,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      // Return true if share sheet opened successfully
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}
