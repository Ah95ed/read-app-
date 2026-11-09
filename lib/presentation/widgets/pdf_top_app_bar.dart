import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';
import 'jump_to_page_dialog.dart';
import 'settings_bottom_sheet.dart';

class PdfTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const PdfTopAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h.clamp(52.0, 68.0));

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();

    return AppBar(
      titleSpacing: 10.w,
      title: Row(
        children: [
          // Book icon
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 22.sp,
          ),
          SizedBox(width: 8.w),

          // Title text
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        // Prominent Jump-to-Page Chip (Page X of Y)
        if (pdfCtrl.totalPages > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
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
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${pdfCtrl.currentPage} / ${pdfCtrl.totalPages}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Scroll direction toggle (Vertical / Horizontal)
        IconButton(
          icon: Icon(
            pdfCtrl.isVerticalScroll
                ? Icons.view_headline_rounded
                : Icons.view_column_rounded,
            size: 20.sp,
          ),
          tooltip: context.tr('scroll_direction'),
          onPressed: () => pdfCtrl.toggleScrollDirection(),
        ),

        // Share document button (Bluetooth, WhatsApp, Telegram, etc.)
        Builder(
          builder: (btnContext) {
            return IconButton(
              icon: pdfCtrl.isSharing
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.share_rounded, size: 20.sp),
              tooltip: context.tr('share_document'),
              onPressed: pdfCtrl.isSharing
                  ? null
                  : () async {
                      final box = btnContext.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;
                      final success = await pdfCtrl.shareDocument(
                        subject: context.tr('share_pdf_subject'),
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
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.print_rounded, size: 20.sp),
          tooltip: context.tr('print'),
          onPressed: pdfCtrl.isPrinting
              ? null
              : () async {
                  final success = await pdfCtrl.printDocument(
                    documentName: title,
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

        // Settings / Appearance & Language
        IconButton(
          icon: Icon(Icons.settings_outlined, size: 20.sp),
          tooltip: context.tr('settings'),
          onPressed: () {
            SettingsBottomSheet.show(context);
          },
        ),

        SizedBox(width: 4.w),
      ],
    );
  }
}
