import '../repositories/pdf_repository.dart';

class SavePageUseCase {
  final IPdfRepository _repository;

  const SavePageUseCase(this._repository);

  Future<bool> execute(String documentKey, int pageNumber) {
    return _repository.saveCurrentPage(documentKey, pageNumber);
  }
}

