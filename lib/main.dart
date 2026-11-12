import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/services/pdf_storage_service.dart';
import 'core/services/print_service.dart';
import 'core/services/share_service.dart';
import 'core/services/storage_service.dart';
import 'data/datasources/pdf_local_datasource.dart';
import 'data/repositories/pdf_repository_impl.dart';
import 'domain/repositories/pdf_repository.dart';
import 'domain/usecases/get_saved_page_usecase.dart';
import 'domain/usecases/prepare_books_usecase.dart';
import 'domain/usecases/print_pdf_usecase.dart';
import 'domain/usecases/save_page_usecase.dart';
import 'domain/usecases/scroll_mode_usecase.dart';
import 'domain/usecases/share_pdf_usecase.dart';
import 'presentation/controllers/app_settings_controller.dart';
import 'presentation/controllers/books_controller.dart';
import 'presentation/controllers/pdf_controller.dart';
import 'presentation/views/book_selection_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final storageService = await StorageService.init();
  const printService = PrintService();
  const shareService = ShareService();
  const pdfStorageService = PdfStorageService();

  // Initialize Data Layer
  final IPdfLocalDataSource localDataSource = PdfLocalDataSourceImpl(
    storageService,
  );
  final IPdfRepository pdfRepository = PdfRepositoryImpl(
    localDataSource: localDataSource,
    printService: printService,
    shareService: shareService,
    pdfStorageService: pdfStorageService,
  );

  // Initialize Domain Use Cases
  final prepareBooksUseCase = PrepareBooksUseCase(pdfRepository);
  final getSavedPageUseCase = GetSavedPageUseCase(pdfRepository);
  final savePageUseCase = SavePageUseCase(pdfRepository);
  final printPdfUseCase = PrintPdfUseCase(pdfRepository);
  final sharePdfUseCase = SharePdfUseCase(pdfRepository);
  final scrollModeUseCase = ScrollModeUseCase(pdfRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsController>(
          create: (_) => AppSettingsController(storageService),
        ),
        ChangeNotifierProvider<BooksController>(
          create: (_) => BooksController(
            getSavedPageUseCase: getSavedPageUseCase,
            prepareBooksUseCase: prepareBooksUseCase,
          ),
        ),
        ChangeNotifierProvider<PdfReaderController>(
          create: (_) => PdfReaderController(
            getSavedPageUseCase: getSavedPageUseCase,
            savePageUseCase: savePageUseCase,
            printPdfUseCase: printPdfUseCase,
            sharePdfUseCase: sharePdfUseCase,
            scrollModeUseCase: scrollModeUseCase,
          ),
        ),
      ],
      child: const BookIqApp(),
    ),
  );
}

class BookIqApp extends StatelessWidget {
  const BookIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<AppSettingsController>();

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Book IQ Reader',
          debugShowCheckedModeBanner: false,
          locale: settingsCtrl.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: settingsCtrl.themeData,
          home: child,
        );
      },
      child: const BookSelectionView(),
    );
  }
}
