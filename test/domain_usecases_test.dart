import 'package:flutter_test/flutter_test.dart';
import 'package:book_iq/core/localization/app_localizations.dart';
import 'package:book_iq/domain/entities/reader_settings.dart';
import 'package:book_iq/domain/repositories/pdf_repository.dart';
import 'package:book_iq/domain/usecases/get_saved_page_usecase.dart';
import 'package:book_iq/domain/usecases/save_page_usecase.dart';
import 'package:book_iq/domain/usecases/print_pdf_usecase.dart';
import 'package:book_iq/domain/usecases/share_pdf_usecase.dart';
import 'package:flutter/material.dart';

class MockPdfRepository implements IPdfRepository {
  int savedPage = 1;
  bool printed = false;
  bool shared = false;

  @override
  Future<int> getLastSavedPage(String documentKey) async => savedPage;

  @override
  Future<bool> saveCurrentPage(String documentKey, int pageNumber) async {
    savedPage = pageNumber;
    return true;
  }

  @override
  Future<bool> printDocument({required String assetPath, required String documentName}) async {
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
    return const ReaderSettings(
      lastPage: 1,
      isVerticalScroll: true,
      themeMode: 'light',
      localeCode: 'ar',
    );
  }

  @override
  Future<bool> saveLocale(String localeCode) async => true;

  @override
  Future<bool> saveScrollDirection(bool isVertical) async => true;

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

    setUp(() {
      repository = MockPdfRepository();
      getSavedPageUseCase = GetSavedPageUseCase(repository);
      savePageUseCase = SavePageUseCase(repository);
      printPdfUseCase = PrintPdfUseCase(repository);
      sharePdfUseCase = SharePdfUseCase(repository);
    });

    test('SavePageUseCase and GetSavedPageUseCase store and retrieve page correctly', () async {
      await savePageUseCase.execute('c1.pdf', 15);
      final page = await getSavedPageUseCase.execute('c1.pdf');
      expect(page, 15);
    });

    test('PrintPdfUseCase invokes print on repository', () async {
      final success = await printPdfUseCase.execute(
        assetPath: 'assets/pdf/c1.pdf',
        documentName: 'TestDoc',
      );
      expect(success, isTrue);
      expect(repository.printed, isTrue);
    });

    test('SharePdfUseCase invokes share on repository', () async {
      final success = await sharePdfUseCase.execute(
        assetPath: 'assets/pdf/c1.pdf',
        subject: 'Share Test',
        text: 'Sharing test book',
      );
      expect(success, isTrue);
      expect(repository.shared, isTrue);
    });
  });

  group('Localization Tests', () {
    test('Arabic localizations translate and substitute placeholders', () {
      final locAr = AppLocalizations(const Locale('ar'));
      final text = locAr.translate('page_x_of_y', args: {'current': 15, 'total': 120});
      expect(text, 'صفحة 15 من 120');

      final jumpTitle = locAr.translate('jump_to_page');
      expect(jumpTitle, 'الانتقال إلى صفحة');

      final shareText = locAr.translate('share_document');
      expect(shareText, contains('بلوتوث'));
    });

    test('English localizations translate and substitute placeholders', () {
      final locEn = AppLocalizations(const Locale('en'));
      final text = locEn.translate('page_x_of_y', args: {'current': 15, 'total': 120});
      expect(text, 'Page 15 of 120');

      final jumpTitle = locEn.translate('jump_to_page');
      expect(jumpTitle, 'Jump to Page');

      final shareText = locEn.translate('share_document');
      expect(shareText, contains('Bluetooth'));
    });
  });
}
