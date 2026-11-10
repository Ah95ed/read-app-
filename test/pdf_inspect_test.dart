import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:book_iq/core/localization/app_localizations.dart';
import 'package:book_iq/core/services/print_service.dart';
import 'package:book_iq/core/services/share_service.dart';
import 'package:book_iq/core/services/storage_service.dart';
import 'package:book_iq/data/datasources/pdf_local_datasource.dart';
import 'package:book_iq/data/repositories/pdf_repository_impl.dart';
import 'package:book_iq/domain/usecases/get_saved_page_usecase.dart';
import 'package:book_iq/domain/usecases/print_pdf_usecase.dart';
import 'package:book_iq/domain/usecases/save_page_usecase.dart';
import 'package:book_iq/domain/usecases/scroll_mode_usecase.dart';
import 'package:book_iq/domain/usecases/share_pdf_usecase.dart';
import 'package:book_iq/presentation/controllers/app_settings_controller.dart';
import 'package:book_iq/presentation/controllers/books_controller.dart';
import 'package:book_iq/presentation/controllers/pdf_controller.dart';
import 'package:book_iq/presentation/views/book_selection_view.dart';
import 'package:book_iq/presentation/views/pdf_viewer_view.dart';

void main() {
  test('Verify c1.pdf and activity.pdf exist and have valid PDF headers', () async {
    for (final path in ['assets/pdf/c1.pdf', 'assets/pdf/activity.pdf']) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path should exist');
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
    }
  });

  testWidgets('Tapping Reading Book navigates to PdfViewerView and mounts SfPdfViewer',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final repo = PdfRepositoryImpl(
      localDataSource: PdfLocalDataSourceImpl(storage),
      printService: const PrintService(),
      shareService: const ShareService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController(storage)),
          ChangeNotifierProvider(
            create: (_) => BooksController(
              getSavedPageUseCase: GetSavedPageUseCase(repo),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PdfReaderController(
              getSavedPageUseCase: GetSavedPageUseCase(repo),
              savePageUseCase: SavePageUseCase(repo),
              printPdfUseCase: PrintPdfUseCase(repo),
              sharePdfUseCase: SharePdfUseCase(repo),
              scrollModeUseCase: ScrollModeUseCase(repo),
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          builder: (_, _) => const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: BookSelectionView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('كتاب القراءة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PdfViewerView), findsOneWidget);
    expect(find.byType(SfPdfViewer), findsOneWidget);
  });
}
