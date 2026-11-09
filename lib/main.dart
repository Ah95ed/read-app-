import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/print_service.dart';
import 'core/services/share_service.dart';
import 'core/services/storage_service.dart';
import 'data/datasources/pdf_local_datasource.dart';
import 'data/repositories/pdf_repository_impl.dart';
import 'domain/repositories/pdf_repository.dart';
import 'domain/usecases/get_saved_page_usecase.dart';
import 'domain/usecases/print_pdf_usecase.dart';
import 'domain/usecases/save_page_usecase.dart';
import 'domain/usecases/share_pdf_usecase.dart';
import 'presentation/controllers/app_settings_controller.dart';
import 'presentation/controllers/pdf_controller.dart';
import 'presentation/views/pdf_viewer_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final storageService = await StorageService.init();
  const printService = PrintService();
  const shareService = ShareService();

  // Initialize Data Layer
  final IPdfLocalDataSource localDataSource = PdfLocalDataSourceImpl(
    storageService,
  );
  final IPdfRepository pdfRepository = PdfRepositoryImpl(
    localDataSource: localDataSource,
    printService: printService,
    shareService: shareService,
  );

  // Initialize Domain Use Cases
  final getSavedPageUseCase = GetSavedPageUseCase(pdfRepository);
  final savePageUseCase = SavePageUseCase(pdfRepository);
  final printPdfUseCase = PrintPdfUseCase(pdfRepository);
  final sharePdfUseCase = SharePdfUseCase(pdfRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsController>(
          create: (_) => AppSettingsController(storageService),
        ),
        ChangeNotifierProvider<PdfReaderController>(
          create: (_) => PdfReaderController(
            getSavedPageUseCase: getSavedPageUseCase,
            savePageUseCase: savePageUseCase,
            printPdfUseCase: printPdfUseCase,
            sharePdfUseCase: sharePdfUseCase,
            assetPath: AppConstants.defaultPdfAsset,
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
      child: const PdfViewerView(),
    );
  }
}
