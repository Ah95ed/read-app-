import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';
import '../widgets/jump_to_page_dialog.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_search_bar.dart';
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
    final pdfCtrl = context.read<PdfReaderController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          pdfCtrl.flushSave();
        }
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            if (pdfCtrl.totalPages > 0) pdfCtrl.toggleSearch();
          },
          const SingleActivator(LogicalKeyboardKey.keyG, control: true): () async {
            if (pdfCtrl.totalPages > 0) {
              final target = await JumpToPageDialog.show(
                context,
                currentPage: pdfCtrl.currentPage,
                totalPages: pdfCtrl.totalPages,
              );
              if (target != null) pdfCtrl.jumpToPage(target);
            }
          },
          const SingleActivator(LogicalKeyboardKey.pageDown): pdfCtrl.nextPage,
          const SingleActivator(LogicalKeyboardKey.pageUp): pdfCtrl.previousPage,
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            if (context.isRtl) {
              pdfCtrl.previousPage();
            } else {
              pdfCtrl.nextPage();
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            if (context.isRtl) {
              pdfCtrl.nextPage();
            } else {
              pdfCtrl.previousPage();
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: const PdfTopAppBar(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Expandable In-Book Search Bar
                Selector<PdfReaderController, bool>(
                  selector: (_, ctrl) => ctrl.isSearchOpen,
                  builder: (context, isSearchOpen, _) {
                    if (!isSearchOpen) return const SizedBox.shrink();
                    return const PdfSearchBar();
                  },
                ),

                // Main PDF Viewport
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Isolated PDF Canvas: NEVER rebuilds on page flips or UI state changes!
                      const RepaintBoundary(
                        child: _SmoothPdfCanvas(),
                      ),

                      // Resumed reading banner listener
                      Selector<PdfReaderController, int?>(
                        selector: (_, ctrl) => ctrl.recentlyRestoredPage,
                        builder: (context, restoredPage, _) {
                          if (!_shownResumeSnackbar &&
                              restoredPage != null &&
                              restoredPage > 1) {
                            _shownResumeSnackbar = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.bookmark_added_rounded,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          context.tr(
                                            'restored_last_page',
                                            args: {'page': restoredPage},
                                          ),
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: pdfCtrl.currentBook.accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              pdfCtrl.clearRestoredNotice();
                            });
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Loading overlay
                      Selector<PdfReaderController, bool>(
                        selector: (_, ctrl) => ctrl.isLoading || !ctrl.isReady,
                        builder: (context, isLoading, _) {
                          if (!isLoading) return const SizedBox.shrink();
                          return Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      pdfCtrl.currentBook.accentColor,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    context.tr('loading_pdf'),
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Error message overlay if PDF fails to load
                      Selector<PdfReaderController, String?>(
                        selector: (_, ctrl) => ctrl.errorMessage,
                        builder: (context, errorMessage, _) {
                          if (errorMessage == null) return const SizedBox.shrink();
                          return Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: EdgeInsets.all(24.r),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 48.sp,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    context.tr('error_loading_pdf'),
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const PdfBottomBar(),
          ),
        ),
      ),
    );
  }
}

/// Immutable config so SfPdfViewer only rebuilds when structural viewer settings change
class _PdfCanvasConfig {
  final bool isReady;
  final String assetPath;
  final int initialPageNumber;
  final PdfScrollDirection scrollDirection;
  final PdfPageLayoutMode pageLayoutMode;
  final PdfInteractionMode interactionMode;

  const _PdfCanvasConfig({
    required this.isReady,
    required this.assetPath,
    required this.initialPageNumber,
    required this.scrollDirection,
    required this.pageLayoutMode,
    required this.interactionMode,
  });

  @override
  bool operator ==(Object other) {
    return other is _PdfCanvasConfig &&
        isReady == other.isReady &&
        assetPath == other.assetPath &&
        scrollDirection == other.scrollDirection &&
        pageLayoutMode == other.pageLayoutMode &&
        interactionMode == other.interactionMode;
  }

  @override
  int get hashCode => Object.hash(
        isReady,
        assetPath,
        scrollDirection,
        pageLayoutMode,
        interactionMode,
      );
}

class _SmoothPdfCanvas extends StatelessWidget {
  const _SmoothPdfCanvas();

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.read<PdfReaderController>();

    return Selector<PdfReaderController, _PdfCanvasConfig>(
      selector: (_, ctrl) => _PdfCanvasConfig(
        isReady: ctrl.isReady,
        assetPath: ctrl.assetPath,
        initialPageNumber: ctrl.initialPageNumber,
        scrollDirection: ctrl.pdfScrollDirection,
        pageLayoutMode: ctrl.pdfPageLayoutMode,
        interactionMode: ctrl.interactionMode,
      ),
      builder: (context, config, _) {
        if (!config.isReady) {
          return const SizedBox.shrink();
        }

        return SfPdfViewer.asset(
          config.assetPath,
          key: ValueKey('${config.assetPath}_${config.scrollDirection}_${config.pageLayoutMode}'),
          controller: pdfCtrl.pdfViewerController,
          initialPageNumber: config.initialPageNumber,
          maxZoomLevel: AppConstants.maxZoom,
          pageSpacing: 6,
          scrollDirection: config.scrollDirection,
          pageLayoutMode: config.pageLayoutMode,
          interactionMode: config.interactionMode,
          enableTextSelection: config.interactionMode == PdfInteractionMode.selection,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: false,
          enableDoubleTapZooming: true,
          onDocumentLoaded: (details) => pdfCtrl.onDocumentLoaded(details),
          onPageChanged: (details) => pdfCtrl.onPageChanged(details.newPageNumber),
          onZoomLevelChanged: (details) => pdfCtrl.syncZoomFromViewer(details.newZoomLevel),
          onDocumentLoadFailed: (details) => pdfCtrl.onDocumentLoadFailed(details),
        );
      },
    );
  }
}
