import '../repositories/pdf_repository.dart';

class GetSavedPageUseCase {
  final IPdfRepository _repository;

  const GetSavedPageUseCase(this._repository);

  Future<int> execute(String documentKey) {
    return _repository.getLastSavedPage(documentKey);
  }
}

