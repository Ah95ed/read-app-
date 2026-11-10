import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/reader_settings.dart';
import '../controllers/pdf_controller.dart';
import 'jump_to_page_dialog.dart';
import 'settings_bottom_sheet.dart';

class PdfTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;

  const PdfTopAppBar({
    super.key,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h.clamp(52.0, 68.0));

  IconData _scrollModeIcon(ReaderScrollMode mode) {
    switch (mode) {
      case ReaderScrollMode.verticalContinuous:
        return Icons.view_headline_rounded;
      case ReaderScrollMode.horizontalContinuous:
        return Icons.view_carousel_rounded;
      case ReaderScrollMode.singlePage:
        return Icons.auto_stories_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();
    final book = pdfCtrl.currentBook;
    final bookTitle = context.tr(book.titleKey);
    final isWideScreen = MediaQuery.sizeOf(context).width >= 620;

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, size: 22.sp),
        tooltip: context.tr('back_to_books'),
        onPressed: () async {
          await pdfCtrl.flushSave();
          if (onBackPressed != null) {
            onBackPressed!();
          } else if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      titleSpacing: 4.w,
      title: Row(
        children: [
          Icon(
            book.icon,
            color: book.accentColor,
            size: 20.sp,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              bookTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        // Prominent Jump-to-Page Chip (Page X / Y)
        if (pdfCtrl.totalPages > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
            child: Tooltip(
              message: context.tr('jump_to_page'),
              child: InkWell(
                onTap: () async {
                  final targetPage = await JumpToPageDialog.show(
                    context,
                    currentPage: pdfCtrl.currentPage,
                    totalPages: pdfCtrl.totalPages,
                  );
                  if (targetPage != null) {
                    pdfCtrl.jumpToPage(targetPage);
                  }
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: book.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: book.accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 15.sp,
                        color: book.accentColor,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '${pdfCtrl.currentPage} / ${pdfCtrl.totalPages}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: book.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // In-book text search button
        IconButton(
          icon: Icon(
            pdfCtrl.isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
            size: 20.sp,
            color: pdfCtrl.isSearchOpen ? AppColors.primary : null,
          ),
          tooltip: context.tr('search'),
          onPressed: pdfCtrl.totalPages > 0 ? pdfCtrl.toggleSearch : null,
          visualDensity: VisualDensity.compact,
        ),

        // Desktop/Tablet wide actions
        if (isWideScreen) ...[
          IconButton(
            icon: Icon(
              pdfCtrl.isPanMode ? Icons.pan_tool_alt_rounded : Icons.text_fields_rounded,
              size: 19.sp,
            ),
            tooltip: context.tr(pdfCtrl.isPanMode ? 'pan_mode' : 'selection_mode'),
            onPressed: pdfCtrl.toggleInteractionMode,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(_scrollModeIcon(pdfCtrl.scrollMode), size: 20.sp),
            tooltip: context.tr('scroll_direction'),
            onPressed: pdfCtrl.cycleScrollMode,
            visualDensity: VisualDensity.compact,
          ),
        ],

        // Share document button (Bluetooth, WhatsApp, Telegram, etc.)
        Builder(
          builder: (btnContext) {
            return IconButton(
              icon: pdfCtrl.isSharing
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.share_rounded, size: 19.sp),
              tooltip: context.tr('share_document'),
              visualDensity: VisualDensity.compact,
              onPressed: pdfCtrl.isSharing
                  ? null
                  : () async {
                      final box = btnContext.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;
                      final success = await pdfCtrl.shareDocument(
                        subject: '$bookTitle - ${context.tr('share_pdf_subject')}',
                        text: context.tr('share_pdf_text'),
                        sharePositionOrigin: origin,
                      );
                      if (context.mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('share_failed')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
            );
          },
        ),

        // Print document button
        IconButton(
          icon: pdfCtrl.isPrinting
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.print_rounded, size: 19.sp),
          tooltip: context.tr('print'),
          visualDensity: VisualDensity.compact,
          onPressed: pdfCtrl.isPrinting
              ? null
              : () async {
                  final success = await pdfCtrl.printDocument(
                    documentName: bookTitle,
                  );
                  if (context.mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('print_failed')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
        ),

        // Settings / Appearance & Language & Scroll Mode
        IconButton(
          icon: Icon(Icons.settings_outlined, size: 19.sp),
          tooltip: context.tr('settings'),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            SettingsBottomSheet.show(context);
          },
        ),

        SizedBox(width: 2.w),
      ],
    );
  }
}
