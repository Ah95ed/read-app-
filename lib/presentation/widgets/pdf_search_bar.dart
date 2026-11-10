import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/pdf_controller.dart';

/// In-book text search bar supporting word/sentence lookup and match navigation
class PdfSearchBar extends StatefulWidget {
  const PdfSearchBar({super.key});

  @override
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _triggerSearch(PdfReaderController ctrl) {
    ctrl.performSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final pdfCtrl = context.watch<PdfReaderController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 4,
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              // Search input field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: context.tr('search_hint'),
                    hintStyle: TextStyle(fontSize: 12.sp),
                    prefixIcon: Icon(Icons.search_rounded, size: 19.sp),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.backspace_outlined, size: 16.sp),
                            onPressed: () {
                              _searchController.clear();
                              pdfCtrl.clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _triggerSearch(pdfCtrl),
                ),
              ),
              SizedBox(width: 6.w),

              // Execute search button
              IconButton(
                icon: Icon(Icons.search_rounded, size: 20.sp, color: AppColors.primary),
                tooltip: context.tr('search'),
                onPressed: _searchController.text.trim().isNotEmpty
                    ? () => _triggerSearch(pdfCtrl)
                    : null,
                visualDensity: VisualDensity.compact,
              ),

              // Search Status / Results Navigation
              if (pdfCtrl.isSearching)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (pdfCtrl.totalSearchCount > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${pdfCtrl.currentSearchIndex} / ${pdfCtrl.totalSearchCount}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 22.sp),
                  tooltip: context.tr('previous_result'),
                  onPressed: pdfCtrl.previousSearchMatch,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22.sp),
                  tooltip: context.tr('next_result'),
                  onPressed: pdfCtrl.nextSearchMatch,
                  visualDensity: VisualDensity.compact,
                ),
              ] else if (pdfCtrl.hasSearchCompleted &&
                  pdfCtrl.searchQuery.isNotEmpty &&
                  pdfCtrl.totalSearchCount == 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    context.tr('no_search_results'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Close search bar button
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20.sp),
                tooltip: context.tr('close'),
                onPressed: pdfCtrl.toggleSearch,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

