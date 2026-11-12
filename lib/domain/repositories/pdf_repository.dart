import 'package:flutter/material.dart';
import '../entities/book_entity.dart';
import '../entities/reader_settings.dart';

/// Progress callback emitted while transferring books from assets to internal storage
typedef BookTransferProgressCallback = void Function(
  int completedCount,
  int totalCount,
  BookEntity currentBook,
);

/// Abstract contract for PDF operations and persistence
abstract class IPdfRepository {
  /// Ensures all catalog books are copied into private internal storage on device
  Future<List<BookEntity>> prepareBooksInInternalStorage(
    List<BookEntity> books, {
    BookTransferProgressCallback? onProgress,
  });

  /// Retrieves the last read page for a given document key
  Future<int> getLastSavedPage(String documentKey);

  /// Saves the current page for a given document key
  Future<bool> saveCurrentPage(String documentKey, int pageNumber);

  /// Retrieves full reader settings
  Future<ReaderSettings> getReaderSettings();

  /// Saves scroll mode preference
  Future<bool> saveScrollMode(ReaderScrollMode mode);

  /// Retrieves scroll mode preference
  Future<ReaderScrollMode> getScrollMode();

  /// Saves theme preference
  Future<bool> saveThemeMode(String mode);

  /// Saves locale preference
  Future<bool> saveLocale(String localeCode);

  /// Prints the specified PDF document (prefers localPath when available)
  Future<bool> printDocument({
    required String assetPath,
    String? localPath,
    required String documentName,
  });

  /// Shares the specified PDF document (via Bluetooth, Messaging apps, etc.)
  Future<bool> shareDocument({
    required String assetPath,
    String? localPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  });
}
