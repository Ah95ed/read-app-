import '../entities/book_entity.dart';
import '../repositories/pdf_repository.dart';

/// Use case that ensures PDF assets are transferred into app-private internal storage.
class PrepareBooksUseCase {
  final IPdfRepository _repository;

  const PrepareBooksUseCase(this._repository);

  Future<List<BookEntity>> execute(
    List<BookEntity> books, {
    BookTransferProgressCallback? onProgress,
  }) {
    return _repository.prepareBooksInInternalStorage(
      books,
      onProgress: onProgress,
    );
  }
}

