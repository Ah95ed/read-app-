import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/usecases/get_saved_page_usecase.dart';
import '../../domain/usecases/prepare_books_usecase.dart';

/// Controller for the Book Selection / Home Screen & startup library transfer (MVC + Provider)
class BooksController extends ChangeNotifier {
  final GetSavedPageUseCase getSavedPageUseCase;
  final PrepareBooksUseCase prepareBooksUseCase;

  List<BookEntity> _books = BookEntity.defaultCatalog();
  bool _isPreparingStorage = true;
  bool _isLoading = false;
  double _preparationProgress = 0.0;
  int _completedTransferCount = 0;
  int _totalTransferCount = BookEntity.defaultCatalog().length;
  String? _currentTransferTitleKey;
  String? _storageError;
  bool _disposed = false;

  BooksController({
    required this.getSavedPageUseCase,
    required this.prepareBooksUseCase,
  }) {
    initializeLibrary();
  }

  List<BookEntity> get books => _books;
  bool get isPreparingStorage => _isPreparingStorage;
  bool get isLoading => _isLoading;
  double get preparationProgress => _preparationProgress;
  int get completedTransferCount => _completedTransferCount;
  int get totalTransferCount => _totalTransferCount;
  String? get currentTransferTitleKey => _currentTransferTitleKey;
  String? get storageError => _storageError;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Transfers both PDFs from bundled assets into app-private internal storage
  /// (when not already cached locally) and loads saved reading progress.
  Future<void> initializeLibrary() async {
    final catalog = BookEntity.defaultCatalog();
    _isPreparingStorage = true;
    _storageError = null;
    _completedTransferCount = 0;
    _totalTransferCount = catalog.length;
    _preparationProgress = 0.0;
    _currentTransferTitleKey = catalog.isNotEmpty ? catalog.first.titleKey : null;
    _safeNotify();

    try {
      final preparedBooks = await prepareBooksUseCase.execute(
        catalog,
        onProgress: (completed, total, currentBook) {
          _completedTransferCount = completed;
          _totalTransferCount = total;
          _currentTransferTitleKey = currentBook.titleKey;
          _preparationProgress = total > 0 ? completed / total : 1.0;
          _safeNotify();
        },
      );

      _books = await _attachSavedPages(preparedBooks);
      _preparationProgress = 1.0;
      _isPreparingStorage = false;
      _safeNotify();
    } catch (e) {
      _storageError = e.toString();
      _isPreparingStorage = false;
      _safeNotify();
    }
  }

  /// Refreshes the last saved page for each book while preserving resolved local paths
  Future<void> loadBooksProgress() async {
    _isLoading = true;
    _safeNotify();

    _books = await _attachSavedPages(_books);
    _isLoading = false;
    _safeNotify();
  }

  Future<List<BookEntity>> _attachSavedPages(List<BookEntity> sourceBooks) async {
    final updated = <BookEntity>[];
    for (final book in sourceBooks) {
      int lastPage = 1;
      try {
        lastPage = await getSavedPageUseCase.execute(book.assetPath);
      } catch (_) {
        lastPage = 1;
      }
      updated.add(book.copyWith(lastSavedPage: lastPage > 0 ? lastPage : 1));
    }
    return updated;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
