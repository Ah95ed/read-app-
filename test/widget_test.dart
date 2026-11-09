import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_iq/core/localization/app_localizations.dart';
import 'package:book_iq/presentation/widgets/jump_to_page_dialog.dart';
import 'package:book_iq/presentation/widgets/zoom_controls_widget.dart';

Widget createTestWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Clean Architecture Widget & Logic Tests', () {
    testWidgets('JumpToPageDialog shows current page and triggers jump callback', (WidgetTester tester) async {
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

      // Check current page is displayed in text field
      expect(find.text('15'), findsOneWidget);
      expect(find.text('/ 100'), findsOneWidget);

      // Enter a new page number e.g. 30
      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(selectedPage, 30);
    });

    testWidgets('JumpToPageDialog validates out of bounds page numbers', (WidgetTester tester) async {
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

      // Enter out of bounds page 999
      await tester.enterText(find.byType(TextField), '999');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should not have jumped
      expect(selectedPage, isNull);
    });

    testWidgets('ZoomControlsWidget triggers zoom callbacks', (WidgetTester tester) async {
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

      // Tap zoom in
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(zoomedIn, isTrue);

      // Tap zoom out
      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(zoomedOut, isTrue);

      // Tap percentage to reset
      await tester.tap(find.text('150%'));
      expect(resetZoomed, isTrue);
    });
  });
}
