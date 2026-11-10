import 'package:flutter/material.dart';
import '../entities/reader_settings.dart';

/// Abstract contract for PDF operations and persistence
abstract class IPdfRepository {
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

  /// Prints the specified PDF asset
  Future<bool> printDocument({
    required String assetPath,
    required String documentName,
  });

  /// Shares the specified PDF document (via Bluetooth, Messaging apps, etc.)
  Future<bool> shareDocument({
    required String assetPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  });
}
