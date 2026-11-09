/// Application constants
class AppConstants {
  AppConstants._();

  /// Default asset PDF path
  static const String defaultPdfAsset = 'assets/pdf/c1.pdf';
  static const String defaultPdfTitle = 'كتاب القراءة';

  /// Storage keys
  static const String keyLastPage = 'pdf_reader_last_page';
  static const String keyScrollDirection = 'pdf_reader_scroll_direction';
  static const String keyThemeMode = 'pdf_reader_theme_mode';
  static const String keyLocale = 'pdf_reader_locale';
  static const String keyBookmarks = 'pdf_reader_bookmarks';

  /// Zoom limits
  static const double minZoom = 1.0;
  static const double maxZoom = 4.0;
  static const double zoomStep = 0.25;
  static const double defaultZoom = 1.0;
}

