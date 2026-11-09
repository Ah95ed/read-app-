import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/app_settings_controller.dart';
import '../controllers/pdf_controller.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<AppSettingsController>();
    final pdfCtrl = context.watch<PdfReaderController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600.w.clamp(320.0, 650.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

                // Sheet title
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 22.sp),
                    SizedBox(width: 8.w),
                    Text(
                      context.tr('settings'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Language section
                Text(
                  context.tr('language'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'ar',
                      label: Text(context.tr('arabic'), style: TextStyle(fontSize: 12.sp)),
                      icon: Icon(Icons.language_rounded, size: 16.sp),
                    ),
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(context.tr('english'), style: TextStyle(fontSize: 12.sp)),
                      icon: Icon(Icons.translate_rounded, size: 16.sp),
                    ),
                  ],
                  selected: {settingsCtrl.currentLocale.languageCode},
                  onSelectionChanged: (set) {
                    settingsCtrl.setLocale(Locale(set.first));
                  },
                ),
                SizedBox(height: 16.h),

                // Theme section
                Text(
                  context.tr('theme'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                SegmentedButton<AppThemeMode>(
                  segments: [
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.light,
                      label: Text(context.tr('theme_light'), style: TextStyle(fontSize: 11.sp)),
                      icon: Icon(Icons.light_mode_outlined, size: 15.sp),
                    ),
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.sepia,
                      label: Text(context.tr('theme_sepia'), style: TextStyle(fontSize: 11.sp)),
                      icon: Icon(Icons.auto_awesome_outlined, size: 15.sp),
                    ),
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.dark,
                      label: Text(context.tr('theme_dark'), style: TextStyle(fontSize: 11.sp)),
                      icon: Icon(Icons.dark_mode_outlined, size: 15.sp),
                    ),
                  ],
                  selected: {settingsCtrl.currentThemeMode},
                  onSelectionChanged: (set) {
                    settingsCtrl.setThemeMode(set.first);
                  },
                ),
                SizedBox(height: 16.h),

                // Scroll direction
                Text(
                  context.tr('scroll_direction'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(context.tr('vertical_scroll'), style: TextStyle(fontSize: 12.sp)),
                      icon: Icon(Icons.swap_vert_rounded, size: 16.sp),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(context.tr('horizontal_scroll'), style: TextStyle(fontSize: 12.sp)),
                      icon: Icon(Icons.swap_horiz_rounded, size: 16.sp),
                    ),
                  ],
                  selected: {pdfCtrl.isVerticalScroll},
                  onSelectionChanged: (set) {
                    pdfCtrl.setScrollDirection(set.first);
                  },
                ),
                SizedBox(height: 16.h),

                // Quick Share button inside settings
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    pdfCtrl.shareDocument(
                      subject: context.tr('share_pdf_subject'),
                      text: context.tr('share_pdf_text'),
                    );
                  },
                  icon: Icon(Icons.share_rounded, size: 18.sp),
                  label: Text(
                    context.tr('share_document'),
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
