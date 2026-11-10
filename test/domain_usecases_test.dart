import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_iq/core/constants/app_constants.dart';
import 'package:book_iq/core/localization/app_localizations.dart';
import 'package:book_iq/domain/entities/book_entity.dart';
import 'package:book_iq/domain/entities/reader_settings.dart';
import 'package:book_iq/domain/repositories/pdf_repository.dart';
import 'package:book_iq/domain/usecases/get_saved_page_usecase.dart';
import 'package:book_iq/domain/usecases/save_page_usecase.dart';
import 'package:book_iq/domain/usecases/print_pdf_usecase.dart';
import 'package:book_iq/domain/usecases/scroll_mode_usecase.dart';
import 'package:book_iq/domain/usecases/share_pdf_usecase.dart';

class MockPdfRepository implements IPdfRepository {
  final Map<String, int> savedPages = {};
  ReaderScrollMode scrollMode = ReaderScrollMode.verticalContinuous;
  bool printed = false;
  bool shared = false;

  @override
  Future<int> getLastSavedPage(String documentKey) async =>
      savedPages[documentKey] ?? 1;

  @override
  Future<bool> saveCurrentPage(String documentKey, int pageNumber) async {
    savedPages[documentKey] = pageNumber;
    return true;
  }

  @override
  Future<bool> printDocument({
    required String assetPath,
    required String documentName,
  }) async {
    printed = true;
    return true;
  }

  @override
  Future<bool> shareDocument({
    required String assetPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) async {
    shared = true;
    return true;
  }

  @override
  Future<ReaderSettings> getReaderSettings() async {
    return ReaderSettings(
      lastPage: 1,
      scrollMode: scrollMode,
      themeMode: 'light',
      localeCode: 'ar',
    );
  }

  @override
  Future<ReaderScrollMode> getScrollMode() async => scrollMode;

  @override
  Future<bool> saveScrollMode(ReaderScrollMode mode) async {
    scrollMode = mode;
    return true;
  }

  @override
  Future<bool> saveLocale(String localeCode) async => true;

  @override
  Future<bool> saveThemeMode(String mode) async => true;
}

void main() {
  group('Domain Use Cases Test', () {
    late MockPdfRepository repository;
    late GetSavedPageUseCase getSavedPageUseCase;
    late SavePageUseCase savePageUseCase;
    late PrintPdfUseCase printPdfUseCase;
    late SharePdfUseCase sharePdfUseCase;
    late ScrollModeUseCase scrollModeUseCase;

    setUp(() {
      repository = MockPdfRepository();
      getSavedPageUseCase = GetSavedPageUseCase(repository);
      savePageUseCase = SavePageUseCase(repository);
      printPdfUseCase = PrintPdfUseCase(repository);
      sharePdfUseCase = SharePdfUseCase(repository);
      scrollModeUseCase = ScrollModeUseCase(repository);
    });

    test('SavePageUseCase and GetSavedPageUseCase store independent pages per book', () async {
      await savePageUseCase.execute(AppConstants.readingPdfAsset, 15);
      await savePageUseCase.execute(AppConstants.activityPdfAsset, 42);

      final readingPage = await getSavedPageUseCase.execute(AppConstants.readingPdfAsset);
      final activityPage = await getSavedPageUseCase.execute(AppConstants.activityPdfAsset);

      expect(readingPage, 15);
      expect(activityPage, 42);
    });

    test('ScrollModeUseCase saves and retrieves smooth scroll modes', () async {
      await scrollModeUseCase.saveMode(ReaderScrollMode.horizontalContinuous);
      final mode = await scrollModeUseCase.getMode();
      expect(mode, ReaderScrollMode.horizontalContinuous);
    });

    test('BookEntity catalog contains Reading and Activity books', () {
      final catalog = BookEntity.defaultCatalog();
      expect(catalog.length, 2);
      expect(catalog[0].type, BookType.reading);
      expect(catalog[0].assetPath, AppConstants.readingPdfAsset);
      expect(catalog[1].type, BookType.activity);
      expect(catalog[1].assetPath, AppConstants.activityPdfAsset);
    });

    test('PrintPdfUseCase invokes print on repository', () async {
      final success = await printPdfUseCase.execute(
        assetPath: AppConstants.readingPdfAsset,
        documentName: 'TestDoc',
      );
      expect(success, isTrue);
      expect(repository.printed, isTrue);
    });

    test('SharePdfUseCase invokes share on repository', () async {
      final success = await sharePdfUseCase.execute(
        assetPath: AppConstants.activityPdfAsset,
        subject: 'Share Test',
        text: 'Sharing test book',
      );
      expect(success, isTrue);
      expect(repository.shared, isTrue);
    });
  });

  group('Localization Tests', () {
    test('Arabic localizations translate books, search, and scroll modes', () {
      final locAr = AppLocalizations(const Locale('ar'));
      expect(locAr.translate('reading_book_title'), 'كتاب القراءة');
      expect(locAr.translate('activity_book_title'), 'كتاب النشاط');
      expect(locAr.translate('search'), 'بحث في الكتاب');
      expect(locAr.translate('page_x_of_y', args: {'current': 15, 'total': 120}), 'صفحة 15 من 120');
      expect(locAr.translate('continue_from_page', args: {'page': 12}), 'متابعة من صفحة 12');
    });

    test('English localizations translate books, search, and scroll modes', () {
      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.translate('reading_book_title'), 'Reading Book');
      expect(locEn.translate('activity_book_title'), 'Activity Book');
      expect(locEn.translate('search'), 'Search in Book');
      expect(locEn.translate('page_x_of_y', args: {'current': 15, 'total': 120}), 'Page 15 of 120');
      expect(locEn.translate('continue_from_page', args: {'page': 12}), 'Continue from page 12');
    });
  });
}
