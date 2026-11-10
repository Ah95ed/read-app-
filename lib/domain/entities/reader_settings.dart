/// Reader scroll/layout modes
enum ReaderScrollMode {
  verticalContinuous,
  horizontalContinuous,
  singlePage,
}

/// Reader preferences and state entity
class ReaderSettings {
  final int lastPage;
  final ReaderScrollMode scrollMode;
  final String themeMode;
  final String localeCode;

  const ReaderSettings({
    required this.lastPage,
    required this.scrollMode,
    required this.themeMode,
    required this.localeCode,
  });

  ReaderSettings copyWith({
    int? lastPage,
    ReaderScrollMode? scrollMode,
    String? themeMode,
    String? localeCode,
  }) {
    return ReaderSettings(
      lastPage: lastPage ?? this.lastPage,
      scrollMode: scrollMode ?? this.scrollMode,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}
