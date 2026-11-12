import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// Service responsible for handling document printing.
class PrintService {
  const PrintService();

  /// Prints a PDF preferring the local internal storage file when available,
  /// and falling back to [assetPath] on Web or if [localPath] is absent.
  Future<bool> printAssetPdf({
    required String assetPath,
    String? localPath,
    String documentName = 'Document',
  }) async {
    try {
      final Uint8List bytes;
      if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          bytes = await localFile.readAsBytes();
        } else {
          bytes = await _loadAssetBytes(assetPath);
        }
      } else {
        bytes = await _loadAssetBytes(assetPath);
      }

      return await Printing.layoutPdf(
        name: documentName,
        onLayout: (format) async => bytes,
      );
    } catch (_) {
      // Return false if print dialog was cancelled or error occurred
      return false;
    }
  }

  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  /// Direct print bytes if already loaded in memory.
  Future<bool> printPdfBytes({
    required Uint8List bytes,
    String documentName = 'Document',
  }) async {
    try {
      return await Printing.layoutPdf(
        name: documentName,
        onLayout: (format) async => bytes,
      );
    } catch (_) {
      return false;
    }
  }
}
