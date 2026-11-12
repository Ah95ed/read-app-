import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/book_entity.dart';
import '../controllers/app_settings_controller.dart';
import '../controllers/books_controller.dart';
import '../controllers/pdf_controller.dart';
import 'pdf_viewer_view.dart';

/// Home screen where the user chooses between the Reading Book and the Activity Book
class BookSelectionView extends StatelessWidget {
  const BookSelectionView({super.key});

  Future<void> _openBook(BuildContext context, BookEntity book) async {
    final pdfCtrl = context.read<PdfReaderController>();
    final booksCtrl = context.read<BooksController>();

    await pdfCtrl.openBook(book);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PdfViewerView(),
      ),
    );

    // Refresh last saved pages when returning from the reader
    if (context.mounted) {
      booksCtrl.loadBooksProgress();
    }
  }

  IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.sepia:
        return Icons.auto_awesome_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  void _cycleTheme(AppSettingsController settingsCtrl) {
    const modes = AppThemeMode.values;
    final next = modes[(modes.indexOf(settingsCtrl.currentThemeMode) + 1) % modes.length];
    settingsCtrl.setThemeMode(next);
  }

  @override
  Widget build(BuildContext context) {
    final booksCtrl = context.watch<BooksController>();
    final settingsCtrl = context.watch<AppSettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16.w,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.library_books_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                context.tr('app_title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // Quick Theme cycle button
          IconButton(
            icon: Icon(_themeIcon(settingsCtrl.currentThemeMode), size: 20.sp),
            tooltip: context.tr('theme'),
            onPressed: () => _cycleTheme(settingsCtrl),
          ),

          // Quick Language toggle button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: OutlinedButton.icon(
              onPressed: settingsCtrl.toggleLocale,
              icon: Icon(Icons.translate_rounded, size: 15.sp),
              label: Text(
                settingsCtrl.currentLocale.languageCode == 'ar' ? 'EN' : 'عربي',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: (booksCtrl.isPreparingStorage || booksCtrl.storageError != null)
            ? _LibraryTransferView(booksCtrl: booksCtrl)
            : LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final books = booksCtrl.books;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32.w : 18.w,
                vertical: 22.h,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Welcome Banner
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [AppColors.primaryDark, AppColors.darkSurface]
                                : [AppColors.primary, AppColors.accent],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 16.r,
                              offset: Offset(0, 6.h),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('choose_book'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWide ? 22.sp.clamp(18.0, 26.0) : 19.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              context.tr('app_subtitle'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: isWide ? 14.sp.clamp(12.0, 16.0) : 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Book Cards Grid / Column
                      if (isWide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < books.length; i++) ...[
                                Expanded(
                                  child: _BookSelectionCard(
                                    book: books[i],
                                    onTap: () => _openBook(context, books[i]),
                                  ),
                                ),
                                if (i < books.length - 1) SizedBox(width: 20.w.clamp(12.0, 28.0)),
                              ],
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < books.length; i++) ...[
                              _BookSelectionCard(
                                book: books[i],
                                onTap: () => _openBook(context, books[i]),
                              ),
                              if (i < books.length - 1) SizedBox(height: 16.h),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookSelectionCard extends StatelessWidget {
  final BookEntity book;
  final VoidCallback onTap;

  const _BookSelectionCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasProgress = book.lastSavedPage > 1;

    return Card(
      elevation: isDark ? 2 : 3,
      shadowColor: book.accentColor.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: book.accentColor.withValues(alpha: isDark ? 0.35 : 0.18),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(20.r.clamp(14.0, 24.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Icon & Saved Page Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.r.clamp(10.0, 18.0)),
                        decoration: BoxDecoration(
                          color: book.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          book.icon,
                          color: book.accentColor,
                          size: 32.sp.clamp(28.0, 42.0),
                        ),
                      ),
                      SizedBox(width: 8.w.clamp(6.0, 14.0)),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w.clamp(8.0, 14.0),
                            vertical: 5.h.clamp(4.0, 8.0),
                          ),
                          decoration: BoxDecoration(
                            color: hasProgress
                                ? book.accentColor.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasProgress
                                    ? Icons.bookmark_added_rounded
                                    : Icons.play_circle_outline_rounded,
                                size: 14.sp.clamp(13.0, 18.0),
                                color: hasProgress ? book.accentColor : theme.hintColor,
                              ),
                              SizedBox(width: 4.w.clamp(3.0, 8.0)),
                              Flexible(
                                child: Text(
                                  hasProgress
                                      ? context.tr(
                                          'continue_from_page',
                                          args: {'page': book.lastSavedPage},
                                        )
                                      : context.tr('start_reading'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp.clamp(10.0, 14.0),
                                    fontWeight: FontWeight.bold,
                                    color: hasProgress ? book.accentColor : theme.hintColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h.clamp(12.0, 22.0)),

                  // Book Title
                  Text(
                    context.tr(book.titleKey),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19.sp.clamp(17.0, 24.0),
                    ),
                  ),
                  SizedBox(height: 6.h.clamp(4.0, 10.0)),

                  // Book Description
                  Text(
                    context.tr(book.descriptionKey),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                      fontSize: 13.sp.clamp(12.0, 16.0),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20.h.clamp(14.0, 24.0)),

                  // Open Book CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.chrome_reader_mode_rounded, size: 18.sp.clamp(16.0, 22.0)),
                      label: Text(
                        context.tr('open_book'),
                        style: TextStyle(
                          fontSize: 14.sp.clamp(13.0, 17.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: book.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h.clamp(10.0, 16.0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryTransferView extends StatelessWidget {
  final BooksController booksCtrl;

  const _LibraryTransferView({required this.booksCtrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = booksCtrl.storageError != null;
    final progress = booksCtrl.preparationProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final currentKey = booksCtrl.currentTransferTitleKey;
    final currentBookTitle = currentKey != null ? context.tr(currentKey) : '';

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
              side: BorderSide(
                color: (hasError ? theme.colorScheme.error : AppColors.primary)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: (hasError ? theme.colorScheme.error : AppColors.primary)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : Icons.folder_copy_rounded,
                      size: 40.sp.clamp(34.0, 52.0),
                      color: hasError ? theme.colorScheme.error : AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    context.tr(
                      hasError ? 'storage_transfer_failed' : 'preparing_library',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp.clamp(16.0, 22.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr('transferring_books_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp.clamp(12.0, 15.0),
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.72),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (!hasError) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : 0.1,
                        minHeight: 10.h.clamp(8.0, 12.0),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentBookTitle.isNotEmpty
                                ? context.tr(
                                    'copying_book_item',
                                    args: {'title': currentBookTitle},
                                  )
                                : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp.clamp(11.0, 14.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          '$percent% (${booksCtrl.completedTransferCount}/${booksCtrl.totalTransferCount})',
                          style: TextStyle(
                            fontSize: 12.sp.clamp(11.0, 14.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: booksCtrl.initializeLibrary,
                        icon: Icon(Icons.refresh_rounded, size: 18.sp),
                        label: Text(
                          context.tr('retry'),
                          style: TextStyle(
                            fontSize: 14.sp.clamp(13.0, 16.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

