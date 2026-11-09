import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';

/// Floating widget providing zoom in, zoom out, and reset zoom actions
class ZoomControlsWidget extends StatelessWidget {
  final double currentZoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  const ZoomControlsWidget({
    super.key,
    required this.currentZoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final zoomPercent = (currentZoom * 100).round();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom out (-)
            IconButton(
              icon: Icon(Icons.remove_rounded, size: 18.sp),
              tooltip: context.tr('zoom_out'),
              onPressed: currentZoom > AppConstants.minZoom ? onZoomOut : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(4.r),
              constraints: const BoxConstraints(),
            ),

            // Zoom percent chip (Tapping resets zoom)
            InkWell(
              onTap: currentZoom != AppConstants.defaultZoom ? onResetZoom : null,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$zoomPercent%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: currentZoom != AppConstants.defaultZoom
                        ? AppColors.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),

            // Zoom in (+)
            IconButton(
              icon: Icon(Icons.add_rounded, size: 18.sp),
              tooltip: context.tr('zoom_in'),
              onPressed: currentZoom < AppConstants.maxZoom ? onZoomIn : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(4.r),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
