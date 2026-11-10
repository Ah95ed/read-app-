import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:book_iq/main.dart' as app;
import 'package:book_iq/presentation/controllers/pdf_controller.dart';
import 'package:book_iq/presentation/views/book_selection_view.dart';
import 'package:book_iq/presentation/views/pdf_viewer_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Full End-to-End: Reading & Activity books open, render pages, jump, search, and save progress',
      (WidgetTester tester) async {
    app.main();
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 1. Verify BookSelectionView renders both books cleanly
    expect(find.byType(BookSelectionView), findsOneWidget);
    expect(find.text('كتاب القراءة'), findsOneWidget);
    expect(find.text('كتاب النشاط'), findsOneWidget);

    // 2. Tap Reading Book
    await tester.tap(find.text('كتاب القراءة'));
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(PdfViewerView), findsOneWidget);
    expect(find.byType(SfPdfViewer), findsOneWidget);

    final ctx1 = tester.element(find.byType(PdfViewerView));
    final pdfCtrl1 = ctx1.read<PdfReaderController>();
    for (int i = 0; i < 24 && pdfCtrl1.isLoading && pdfCtrl1.errorMessage == null; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(pdfCtrl1.errorMessage, isNull);
    expect(pdfCtrl1.isLoading, isFalse);
    expect(pdfCtrl1.totalPages, 128);

    final viewerSize1 = tester.getSize(find.byType(SfPdfViewer));
    expect(viewerSize1.width, greaterThan(300));
    expect(viewerSize1.height, greaterThan(300));

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(RawImage), findsWidgets, reason: 'c1.pdf pages must render visually');

    // 3. Jump to page 10 and verify
    expect(pdfCtrl1.jumpToPage(10), isTrue);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(pdfCtrl1.currentPage, 10);

    // 4. Open and close search bar
    await tester.tap(find.byIcon(Icons.search_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 5. Go back to BookSelectionView and verify saved progress badge updated
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(BookSelectionView), findsOneWidget);
    expect(find.text('متابعة من صفحة 10'), findsOneWidget);

    // 6. Tap Activity Book
    await tester.tap(find.text('كتاب النشاط'));
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(PdfViewerView), findsOneWidget);
    final ctx2 = tester.element(find.byType(PdfViewerView));
    final pdfCtrl2 = ctx2.read<PdfReaderController>();
    for (int i = 0; i < 24 && pdfCtrl2.isLoading && pdfCtrl2.errorMessage == null; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(pdfCtrl2.errorMessage, isNull);
    expect(pdfCtrl2.isLoading, isFalse);
    expect(pdfCtrl2.totalPages, 112);

    final viewerSize2 = tester.getSize(find.byType(SfPdfViewer));
    expect(viewerSize2.width, greaterThan(300));
    expect(viewerSize2.height, greaterThan(300));

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(RawImage), findsWidgets, reason: 'activity.pdf pages must render visually');
  });
}
