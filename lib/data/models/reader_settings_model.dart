import '../../domain/entities/reader_settings.dart';

class ReaderSettingsModel extends ReaderSettings {
  const ReaderSettingsModel({
    required super.lastPage,
    required super.scrollMode,
    required super.themeMode,
    required super.localeCode,
  });

  factory ReaderSettingsModel.fromValues({
    required int lastPage,
    required String scrollModeStr,
    required String themeMode,
    required String localeCode,
  }) {
    final mode = ReaderScrollMode.values.firstWhere(
      (e) => e.name == scrollModeStr,
      orElse: () => ReaderScrollMode.verticalContinuous,
    );
    return ReaderSettingsModel(
      lastPage: lastPage,
      scrollMode: mode,
      themeMode: themeMode,
      localeCode: localeCode,
    );
  }
}
