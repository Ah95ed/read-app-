import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

/// Modal dialog to jump directly to any page by typing the number or pressing Enter/OK
class JumpToPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  const JumpToPageDialog({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  static Future<int?> show(
    BuildContext context, {
    required int currentPage,
    required int totalPages,
  }) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => JumpToPageDialog(
        currentPage: currentPage,
        totalPages: totalPages,
        onPageSelected: (page) => Navigator.of(ctx).pop(page),
      ),
    );
  }

  @override
  State<JumpToPageDialog> createState() => _JumpToPageDialogState();
}

class _JumpToPageDialogState extends State<JumpToPageDialog> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentPage.toString());
    _focusNode = FocusNode();
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textController.text.length,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = context.tr('invalid_page_number', args: {'total': widget.totalPages});
      });
      return;
    }

    final pageNumber = int.tryParse(text);
    if (pageNumber == null || pageNumber < 1 || pageNumber > widget.totalPages) {
      setState(() {
        _errorMessage = context.tr('invalid_page_number', args: {'total': widget.totalPages});
      });
      return;
    }

    widget.onPageSelected(pageNumber);
  }

  void _setPage(int page) {
    _textController.text = page.toString();
    _handleSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420.w.clamp(280.0, 480.0),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon and title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('jump_to_page'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            context.tr('enter_page_number', args: {'total': widget.totalPages}),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.sp,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Text input for page number
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.go,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('page_number_hint'),
                    prefixIcon: Icon(Icons.tag_rounded, size: 18.sp),
                    suffixText: '/ ${widget.totalPages}',
                    suffixStyle: TextStyle(fontSize: 12.sp),
                    errorText: _errorMessage,
                    errorStyle: TextStyle(fontSize: 11.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                SizedBox(height: 12.h),

                // Quick navigation shortcuts
                if (widget.totalPages > 1) ...[
                  Text(
                    context.tr('quick_jump'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.first_page_rounded, size: 13.sp),
                        label: Text('1 (${context.tr('first_page')})', style: TextStyle(fontSize: 10.sp)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _setPage(1),
                      ),
                      if (widget.totalPages >= 4)
                        ActionChip(
                          avatar: Icon(Icons.density_medium_rounded, size: 11.sp),
                          label: Text(
                            '${widget.totalPages ~/ 2} (${context.tr('middle_page')})',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () => _setPage(widget.totalPages ~/ 2),
                        ),
                      ActionChip(
                        avatar: Icon(Icons.last_page_rounded, size: 13.sp),
                        label: Text('${widget.totalPages} (${context.tr('last_page')})', style: TextStyle(fontSize: 10.sp)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _setPage(widget.totalPages),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],

                // Action buttons with Wrap to prevent horizontal overflow on narrow screens
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(context.tr('cancel'), style: TextStyle(fontSize: 12.sp)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _handleSubmit,
                      icon: Icon(Icons.check_rounded, size: 15.sp),
                      label: Text(context.tr('ok'), style: TextStyle(fontSize: 12.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
