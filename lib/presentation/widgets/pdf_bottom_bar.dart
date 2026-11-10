import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';
import 'jump_to_page_dialog.dart';
import 'zoom_controls_widget.dart';

class PdfBottomBar extends StatefulWidget {
  const PdfBottomBar({super.key});

  @override
  State<PdfBottomBar> createState() => _PdfBottomBarState();
}

class _PdfBottomBarState extends State<PdfBottomBar> {
  bool _isDragging = false;
  double _dragValue = 1.0;

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = pdfCtrl.currentBook.accentColor;

    if (pdfCtrl.totalPages <= 0) {
      return const SizedBox.shrink();
    }

    final total = pdfCtrl.totalPages;
    final current = pdfCtrl.currentPage.clamp(1, total);
    final sliderVal = _isDragging
        ? _dragValue.clamp(1.0, total.toDouble())
        : current.toDouble();

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
            // Smooth Page Slider with Prev / Next arrows
            Row(
              children: [
                // Previous page button
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded, size: 22.sp),
                  tooltip: context.tr('previous_page'),
                  onPressed: current > 1 ? pdfCtrl.previousPage : null,
                  visualDensity: VisualDensity.compact,
                ),

                // Non-blocking interactive slider (only jumps on release for ultra-smooth scrubbing)
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.5.r),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 13.r),
                      trackHeight: 3.h,
                      activeTrackColor: accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor: accent,
                      valueIndicatorColor: accent,
                      showValueIndicator: ShowValueIndicator.onDrag,
                    ),
                    child: Slider(
                      min: 1.0,
                      max: total > 1 ? total.toDouble() : 1.0,
                      divisions: total > 1 ? total - 1 : null,
                      label: '${sliderVal.round()}',
                      value: sliderVal,
                      onChangeStart: (val) {
                        setState(() {
                          _isDragging = true;
                          _dragValue = val;
                        });
                      },
                      onChanged: total > 1
                          ? (val) {
                              setState(() {
                                _dragValue = val;
                              });
                            }
                          : null,
                      onChangeEnd: (val) {
                        setState(() {
                          _isDragging = false;
                        });
                        pdfCtrl.jumpToPage(val.round());
                      },
                    ),
                  ),
                ),

                // Next page button
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded, size: 22.sp),
                  tooltip: context.tr('next_page'),
                  onPressed: current < total ? pdfCtrl.nextPage : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Bottom actions: Jump dialog quick button + Interaction toggle on left, Zoom controls on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                        _isDragging
                            ? '${context.tr('page')} ${_dragValue.round()}'
                            : context.tr('jump'),
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: accent,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // Interaction Mode quick toggle (Pan vs Selection)
                    Tooltip(
                      message: context.tr(pdfCtrl.isPanMode ? 'pan_mode' : 'selection_mode'),
                      child: InkWell(
                        onTap: pdfCtrl.toggleInteractionMode,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            pdfCtrl.isPanMode
                                ? Icons.pan_tool_alt_rounded
                                : Icons.text_fields_rounded,
                            size: 16.sp,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
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
