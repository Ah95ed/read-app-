import '../../domain/entities/reader_settings.dart';

class ReaderSettingsModel extends ReaderSettings {
  const ReaderSettingsModel({
    required super.lastPage,
    required super.isVerticalScroll,
    required super.themeMode,
    required super.localeCode,
  });

  factory ReaderSettingsModel.fromValues({
    required int lastPage,
    required bool isVerticalScroll,
    required String themeMode,
    required String localeCode,
  }) {
    return ReaderSettingsModel(
      lastPage: lastPage,
      isVerticalScroll: isVerticalScroll,
      themeMode: themeMode,
      localeCode: localeCode,
    );
  }
}

