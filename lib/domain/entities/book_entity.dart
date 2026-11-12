import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

enum BookType { reading, activity }

/// Represents a book available in the application library
class BookEntity {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String assetPath;
  final String fileName;
  final BookType type;
  final Color accentColor;
  final IconData icon;
  final int lastSavedPage;
  final String? localPath;

  const BookEntity({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.assetPath,
    required this.fileName,
    required this.type,
    required this.accentColor,
    required this.icon,
    this.lastSavedPage = 1,
    this.localPath,
  });

  BookEntity copyWith({
    int? lastSavedPage,
    String? localPath,
  }) {
    return BookEntity(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      assetPath: assetPath,
      fileName: fileName,
      type: type,
      accentColor: accentColor,
      icon: icon,
      lastSavedPage: lastSavedPage ?? this.lastSavedPage,
      localPath: localPath ?? this.localPath,
    );
  }

  /// Default library catalog containing the Reading Book and Activity Book
  static List<BookEntity> defaultCatalog() => const [
        BookEntity(
          id: 'reading_book',
          titleKey: 'reading_book_title',
          descriptionKey: 'reading_book_desc',
          assetPath: AppConstants.readingPdfAsset,
          fileName: 'c1_reading.pdf',
          type: BookType.reading,
          accentColor: AppColors.primary,
          icon: Icons.menu_book_rounded,
        ),
        BookEntity(
          id: 'activity_book',
          titleKey: 'activity_book_title',
          descriptionKey: 'activity_book_desc',
          assetPath: AppConstants.activityPdfAsset,
          fileName: 'activity.pdf',
          type: BookType.activity,
          accentColor: AppColors.activityPrimary,
          icon: Icons.edit_document,
        ),
      ];
}

