import '../repositories/pdf_repository.dart';

class PrintPdfUseCase {
  final IPdfRepository _repository;

  const PrintPdfUseCase(this._repository);

  Future<bool> execute({
    required String assetPath,
    required String documentName,
  }) {
    return _repository.printDocument(
      assetPath: assetPath,
      documentName: documentName,
    );
  }
}

