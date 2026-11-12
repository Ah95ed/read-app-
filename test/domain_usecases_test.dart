import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_iq/core/constants/app_constants.dart';
import 'package:book_iq/core/localization/app_localizations.dart';
import 'package:book_iq/core/services/pdf_storage_service.dart';
import 'package:book_iq/domain/entities/book_entity.dart';
import 'package:book_iq/domain/entities/reader_settings.dart';
import 'package:book_iq/domain/repositories/pdf_repository.dart';
import 'package:book_iq/domain/usecases/get_saved_page_usecase.dart';
import 'package:book_iq/domain/usecases/prepare_books_usecase.dart';
import 'package:book_iq/domain/usecases/save_page_usecase.dart';
import 'package:book_iq/domain/usecases/print_pdf_usecase.dart';
import 'package:book_iq/domain/usecases/scroll_mode_usecase.dart';
import 'package:book_iq/domain/usecases/share_pdf_usecase.dart';

class MockPdfRepository implements IPdfRepository {
  final Map<String, int> savedPages = {};
  ReaderScrollMode scrollMode = ReaderScrollMode.verticalContinuous;
  bool printed = false;
  bool shared = false;
  String? lastLocalPath;

  @override
  Future<List<BookEntity>> prepareBooksInInternalStorage(
    List<BookEntity> books, {
    BookTransferProgressCallback? onProgress,
  }) async {
    final result = <BookEntity>[];
    for (int i = 0; i < books.length; i++) {
      final b = books[i];
      onProgress?.call(i, books.length, b);
      result.add(b.copyWith(localPath: '/internal/.books_vault/${b.fileName}'));
      onProgress?.call(i + 1, books.length, b);
    }
    return result;
  }

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
    String? localPath,
    required String documentName,
  }) async {
    printed = true;
    lastLocalPath = localPath;
    return true;
  }

  @override
  Future<bool> shareDocument({
    required String assetPath,
    String? localPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) async {
    shared = true;
    lastLocalPath = localPath;
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
    late PrepareBooksUseCase prepareBooksUseCase;
    late PrintPdfUseCase printPdfUseCase;
    late SharePdfUseCase sharePdfUseCase;
    late ScrollModeUseCase scrollModeUseCase;

    setUp(() {
      repository = MockPdfRepository();
      getSavedPageUseCase = GetSavedPageUseCase(repository);
      savePageUseCase = SavePageUseCase(repository);
      prepareBooksUseCase = PrepareBooksUseCase(repository);
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
        localPath: '/internal/.books_vault/c1_reading.pdf',
        documentName: 'TestDoc',
      );
      expect(success, isTrue);
      expect(repository.printed, isTrue);
      expect(repository.lastLocalPath, '/internal/.books_vault/c1_reading.pdf');
    });

    test('SharePdfUseCase invokes share on repository', () async {
      final success = await sharePdfUseCase.execute(
        assetPath: AppConstants.activityPdfAsset,
        localPath: '/internal/.books_vault/activity.pdf',
        subject: 'Share Test',
        text: 'Sharing test book',
      );
      expect(success, isTrue);
      expect(repository.shared, isTrue);
      expect(repository.lastLocalPath, '/internal/.books_vault/activity.pdf');
    });

    test('PrepareBooksUseCase assigns local internal storage paths and emits progress', () async {
      final progressSteps = <int>[];
      final prepared = await prepareBooksUseCase.execute(
        BookEntity.defaultCatalog(),
        onProgress: (completed, total, _) => progressSteps.add(completed),
      );
      expect(prepared.length, 2);
      expect(prepared[0].localPath, '/internal/.books_vault/c1_reading.pdf');
      expect(prepared[1].localPath, '/internal/.books_vault/activity.pdf');
      expect(progressSteps, [0, 1, 1, 2]);
    });
  });

  group('PdfStorageService Internal Storage Tests', () {
    test('copies asset bytes into hidden .books_vault directory once and reuses cached file', () async {
      final tempDir = await Directory.systemTemp.createTemp('book_iq_vault_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      int assetLoadCount = 0;
      final fakeBytes = Uint8List.fromList(List<int>.generate(2048, (i) => i % 256));
      final storageService = PdfStorageService(
        baseDirectoryProvider: () async => tempDir,
        assetLoader: (_) async {
          assetLoadCount++;
          return ByteData.sublistView(fakeBytes);
        },
      );

      final firstPath = await storageService.ensureBookStored(
        assetPath: AppConstants.readingPdfAsset,
        fileName: 'c1_reading.pdf',
      );
      expect(firstPath, isNotNull);
      expect(firstPath!, contains('.books_vault'));
      expect(File(firstPath).existsSync(), isTrue);
      expect(File(firstPath).lengthSync(), 2048);
      expect(assetLoadCount, 1);

      // Second call must reuse internal file without re-reading asset bundle
      final secondPath = await storageService.ensureBookStored(
        assetPath: AppConstants.readingPdfAsset,
        fileName: 'c1_reading.pdf',
      );
      expect(secondPath, firstPath);
      expect(assetLoadCount, 1);
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
