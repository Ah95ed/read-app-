import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// Service responsible for handling document printing
class PrintService {
  const PrintService();

  /// Prints a PDF from an asset bundle path
  Future<bool> printAssetPdf({
    required String assetPath,
    String documentName = 'Document',
  }) async {
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      return await Printing.layoutPdf(
        name: documentName,
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      // Return false if print dialog was cancelled or error occurred
      return false;
    }
  }

  /// Direct print bytes if already loaded in memory
  Future<bool> printPdfBytes({
    required Uint8List bytes,
    String documentName = 'Document',
  }) async {
    try {
      return await Printing.layoutPdf(
        name: documentName,
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      return false;
    }
  }
}

