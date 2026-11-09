/// Reader preferences and state entity
class ReaderSettings {
  final int lastPage;
  final bool isVerticalScroll;
  final String themeMode;
  final String localeCode;

  const ReaderSettings({
    required this.lastPage,
    required this.isVerticalScroll,
    required this.themeMode,
    required this.localeCode,
  });

  ReaderSettings copyWith({
    int? lastPage,
    bool? isVerticalScroll,
    String? themeMode,
    String? localeCode,
  }) {
    return ReaderSettings(
      lastPage: lastPage ?? this.lastPage,
      isVerticalScroll: isVerticalScroll ?? this.isVerticalScroll,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

