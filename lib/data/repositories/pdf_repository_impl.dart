import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/pdf_storage_service.dart';
import '../../core/services/print_service.dart';
import '../../core/services/share_service.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/pdf_local_datasource.dart';
import '../models/reader_settings_model.dart';

class PdfRepositoryImpl implements IPdfRepository {
  final IPdfLocalDataSource localDataSource;
  final PrintService printService;
  final ShareService shareService;
  final PdfStorageService pdfStorageService;

  PdfRepositoryImpl({
    required this.localDataSource,
    required this.printService,
    required this.shareService,
    this.pdfStorageService = const PdfStorageService(),
  });

  @override
  Future<List<BookEntity>> prepareBooksInInternalStorage(
    List<BookEntity> books, {
    BookTransferProgressCallback? onProgress,
  }) async {
    final prepared = <BookEntity>[];
    final total = books.length;

    for (int i = 0; i < total; i++) {
      final book = books[i];
      onProgress?.call(i, total, book);

      final localPath = await pdfStorageService.ensureBookStored(
        assetPath: book.assetPath,
        fileName: book.fileName,
      );
      prepared.add(book.copyWith(localPath: localPath));
      onProgress?.call(i + 1, total, book);
    }

    return prepared;
  }

  @override
  Future<int> getLastSavedPage(String documentKey) {
    return localDataSource.getLastPage(documentKey);
  }

  @override
  Future<bool> saveCurrentPage(String documentKey, int pageNumber) {
    return localDataSource.saveLastPage(documentKey, pageNumber);
  }

  @override
  Future<ReaderSettings> getReaderSettings() async {
    final lastPage = await localDataSource.getLastPage(AppConstants.defaultPdfAsset);
    final scrollModeStr = await localDataSource.getScrollMode();
    final theme = await localDataSource.getThemeMode();
    final locale = await localDataSource.getLocale();

    return ReaderSettingsModel.fromValues(
      lastPage: lastPage,
      scrollModeStr: scrollModeStr,
      themeMode: theme,
      localeCode: locale,
    );
  }

  @override
  Future<bool> saveScrollMode(ReaderScrollMode mode) {
    return localDataSource.saveScrollMode(mode.name);
  }

  @override
  Future<ReaderScrollMode> getScrollMode() async {
    final modeStr = await localDataSource.getScrollMode();
    return ReaderScrollMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => ReaderScrollMode.verticalContinuous,
    );
  }

  @override
  Future<bool> saveThemeMode(String mode) {
    return localDataSource.saveThemeMode(mode);
  }

  @override
  Future<bool> saveLocale(String localeCode) {
    return localDataSource.saveLocale(localeCode);
  }

  @override
  Future<bool> printDocument({
    required String assetPath,
    String? localPath,
    required String documentName,
  }) {
    return printService.printAssetPdf(
      assetPath: assetPath,
      localPath: localPath,
      documentName: documentName,
    );
  }

  @override
  Future<bool> shareDocument({
    required String assetPath,
    String? localPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) {
    return shareService.shareAssetPdf(
      assetPath: assetPath,
      localPath: localPath,
      subject: subject,
      text: text,
      fileName: fileName,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
