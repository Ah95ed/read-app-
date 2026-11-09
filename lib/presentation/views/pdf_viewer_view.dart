import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_top_app_bar.dart';

class PdfViewerView extends StatefulWidget {
  const PdfViewerView({super.key});

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  bool _shownResumeSnackbar = false;

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();

    // Show resumed reading snackbar once if restored
    if (!_shownResumeSnackbar &&
        pdfCtrl.recentlyRestoredPage != null &&
        pdfCtrl.recentlyRestoredPage! > 1) {
      _shownResumeSnackbar = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr(
                      'restored_last_page',
                      args: {'page': pdfCtrl.recentlyRestoredPage},
                    ),
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            duration: const Duration(seconds: 4),
          ),
        );
        pdfCtrl.clearRestoredNotice();
      });
    }

    return Scaffold(
      appBar: PdfTopAppBar(
        title: context.tr('book_title'),
      ),
      body: Stack(
        children: [
          // PDF Viewer
          SfPdfViewer.asset(
            pdfCtrl.assetPath,
            controller: pdfCtrl.pdfViewerController,
            scrollDirection: pdfCtrl.isVerticalScroll
                ? PdfScrollDirection.vertical
                : PdfScrollDirection.horizontal,
            pageLayoutMode: pdfCtrl.isVerticalScroll
                ? PdfPageLayoutMode.continuous
                : PdfPageLayoutMode.single,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            onDocumentLoaded: (details) {
              pdfCtrl.onDocumentLoaded(details);
            },
            onPageChanged: (details) {
              pdfCtrl.onPageChanged(details.newPageNumber);
            },
            onDocumentLoadFailed: (details) {
              pdfCtrl.onDocumentLoadFailed(details);
            },
          ),

          // Loading overlay
          if (pdfCtrl.isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      context.tr('loading_pdf'),
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // Error message overlay if PDF fails to load
          if (pdfCtrl.errorMessage != null)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.all(24.r),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
                    SizedBox(height: 12.h),
                    Text(
                      context.tr('error_loading_pdf'),
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      pdfCtrl.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const PdfBottomBar(),
    );
  }
}
