import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';
import 'jump_to_page_dialog.dart';
import 'zoom_controls_widget.dart';

class PdfBottomBar extends StatelessWidget {
  const PdfBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (pdfCtrl.totalPages <= 0) {
      return const SizedBox.shrink();
    }

    final total = pdfCtrl.totalPages;
    final current = pdfCtrl.currentPage.clamp(1, total);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page Slider with Prev / Next arrows
            Row(
              children: [
                // Previous page button
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded, size: 22.sp),
                  tooltip: context.tr('page'),
                  onPressed: current > 1
                      ? () => pdfCtrl.jumpToPage(current - 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),

                // Interactive slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 13.r),
                      trackHeight: 3.h,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      min: 1.0,
                      max: total.toDouble(),
                      value: current.toDouble(),
                      onChanged: (val) {
                        pdfCtrl.jumpToPage(val.round());
                      },
                    ),
                  ),
                ),

                // Next page button
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded, size: 22.sp),
                  tooltip: context.tr('page'),
                  onPressed: current < total
                      ? () => pdfCtrl.jumpToPage(current + 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Bottom actions: Jump dialog quick button on left, Zoom controls on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quick jump button
                OutlinedButton.icon(
                  onPressed: () async {
                    final targetPage = await JumpToPageDialog.show(
                      context,
                      currentPage: pdfCtrl.currentPage,
                      totalPages: pdfCtrl.totalPages,
                    );
                    if (targetPage != null) {
                      pdfCtrl.jumpToPage(targetPage);
                    }
                  },
                  icon: Icon(Icons.directions_rounded, size: 15.sp),
                  label: Text(
                    context.tr('jump'),
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  ),
                ),

                // Zoom Controls widget
                ZoomControlsWidget(
                  currentZoom: pdfCtrl.zoomLevel,
                  onZoomIn: pdfCtrl.zoomIn,
                  onZoomOut: pdfCtrl.zoomOut,
                  onResetZoom: pdfCtrl.resetZoom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
