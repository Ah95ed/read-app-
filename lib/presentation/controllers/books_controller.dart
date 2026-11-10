import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/usecases/get_saved_page_usecase.dart';

/// Controller for the Book Selection / Home Screen (MVC + Provider)
class BooksController extends ChangeNotifier {
  final GetSavedPageUseCase getSavedPageUseCase;

  List<BookEntity> _books = BookEntity.defaultCatalog();
  bool _isLoading = true;

  BooksController({required this.getSavedPageUseCase}) {
    loadBooksProgress();
  }

  List<BookEntity> get books => _books;
  bool get isLoading => _isLoading;

  /// Loads or refreshes the last saved page for each book in the catalog
  Future<void> loadBooksProgress() async {
    _isLoading = true;
    notifyListeners();

    final catalog = BookEntity.defaultCatalog();
    final updated = <BookEntity>[];

    for (final book in catalog) {
      int lastPage = 1;
      try {
        lastPage = await getSavedPageUseCase.execute(book.assetPath);
      } catch (_) {
        lastPage = 1;
      }
      updated.add(book.copyWith(lastSavedPage: lastPage > 0 ? lastPage : 1));
    }

    _books = updated;
    _isLoading = false;
    notifyListeners();
  }
}

