import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Transfers and manages PDF books inside the app's private internal storage.
///
/// Copies PDF assets once into a hidden app-private subdirectory
/// (`getApplicationSupportDirectory()/.books_vault`) so subsequent reads,
/// printing, and sharing access local internal files directly without
/// re-extracting from the asset bundle.
class PdfStorageService {
  static const String _vaultFolderName = '.books_vault';

  final Future<Directory> Function()? baseDirectoryProvider;
  final Future<ByteData> Function(String assetPath)? assetLoader;

  const PdfStorageService({
    this.baseDirectoryProvider,
    this.assetLoader,
  });

  /// Resolves the hidden internal vault directory on the device.
  Future<Directory> getVaultDirectory() async {
    final baseDir = baseDirectoryProvider != null
        ? await baseDirectoryProvider!()
        : await getApplicationSupportDirectory();

    final vaultDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}$_vaultFolderName',
    );
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  /// Ensures [assetPath] is stored in internal storage under [fileName].
  ///
  /// Returns the local internal file path on native platforms, or `null` on Web
  /// (where `dart:io` files are unavailable and assets are streamed directly).
  Future<String?> ensureBookStored({
    required String assetPath,
    required String fileName,
  }) async {
    if (kIsWeb) return null;

    final vaultDir = await getVaultDirectory();
    final targetPath = '${vaultDir.path}${Platform.pathSeparator}$fileName';
    final targetFile = File(targetPath);

    // Already extracted atomically on a previous launch
    if (await targetFile.exists() && await targetFile.length() > 0) {
      return targetFile.path;
    }

    final ByteData byteData = assetLoader != null
        ? await assetLoader!(assetPath)
        : await rootBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    // Atomic write via temporary file to avoid partial/corrupted files if interrupted
    final tempFile = File('$targetPath.tmp');
    await tempFile.writeAsBytes(bytes, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    final savedFile = await tempFile.rename(targetPath);
    return savedFile.path;
  }

  /// Checks whether [fileName] already exists with non-zero bytes in internal storage.
  Future<String?> getExistingBookPath(String fileName) async {
    if (kIsWeb) return null;
    final vaultDir = await getVaultDirectory();
    final targetFile = File(
      '${vaultDir.path}${Platform.pathSeparator}$fileName',
    );
    if (await targetFile.exists() && await targetFile.length() > 0) {
      return targetFile.path;
    }
    return null;
  }
}
