/// Application constants
class AppConstants {
  AppConstants._();

  /// Asset PDF paths
  static const String readingPdfAsset = 'assets/pdf/c1.pdf';
  static const String activityPdfAsset = 'assets/pdf/activity.pdf';

  /// Default fallback PDF asset
  static const String defaultPdfAsset = readingPdfAsset;

  /// Storage keys
  static const String keyLastPage = 'pdf_reader_last_page';
  static const String keyScrollMode = 'pdf_reader_scroll_mode';
  static const String keyThemeMode = 'pdf_reader_theme_mode';
  static const String keyLocale = 'pdf_reader_locale';
  static const String keyBookmarks = 'pdf_reader_bookmarks';

  /// Zoom limits
  static const double minZoom = 1.0;
  static const double maxZoom = 4.0;
  static const double zoomStep = 0.25;
  static const double defaultZoom = 1.0;
}
