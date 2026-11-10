import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:book_iq/core/constants/app_constants.dart';
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
import 'package:book_iq/presentation/widgets/jump_to_page_dialog.dart';
import 'package:book_iq/presentation/widgets/zoom_controls_widget.dart';

const List<LocalizationsDelegate<dynamic>> _testDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget createTestWidget(Widget child, {Locale locale = const Locale('ar')}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _testDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Clean Architecture Widget & Logic Tests', () {
    testWidgets('BookSelectionView renders Reading and Activity books with saved progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        '${AppConstants.keyLastPage}_${AppConstants.readingPdfAsset}': 18,
        '${AppConstants.keyLastPage}_${AppConstants.activityPdfAsset}': 7,
      });

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
              localizationsDelegates: _testDelegates,
              home: BookSelectionView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both books and their independent saved progress appear
      expect(find.text('كتاب القراءة'), findsOneWidget);
      expect(find.text('كتاب النشاط'), findsOneWidget);
      expect(find.text('متابعة من صفحة 18'), findsOneWidget);
      expect(find.text('متابعة من صفحة 7'), findsOneWidget);
    });

    testWidgets('JumpToPageDialog shows current page and triggers jump callback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? selectedPage;

      await tester.pumpWidget(
        createTestWidget(
          JumpToPageDialog(
            currentPage: 15,
            totalPages: 100,
            onPageSelected: (page) {
              selectedPage = page;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('15'), findsOneWidget);
      expect(find.text('/ 100'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(selectedPage, 30);
    });

    testWidgets('JumpToPageDialog validates out of bounds page numbers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? selectedPage;

      await tester.pumpWidget(
        createTestWidget(
          JumpToPageDialog(
            currentPage: 10,
            totalPages: 50,
            onPageSelected: (page) {
              selectedPage = page;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(selectedPage, isNull);
    });

    testWidgets('ZoomControlsWidget triggers zoom callbacks',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool zoomedIn = false;
      bool zoomedOut = false;
      bool resetZoomed = false;

      await tester.pumpWidget(
        createTestWidget(
          ZoomControlsWidget(
            currentZoom: 1.5,
            onZoomIn: () => zoomedIn = true,
            onZoomOut: () => zoomedOut = true,
            onResetZoom: () => resetZoomed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('150%'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(zoomedIn, isTrue);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(zoomedOut, isTrue);

      await tester.tap(find.text('150%'));
      expect(resetZoomed, isTrue);
    });
  });
}
