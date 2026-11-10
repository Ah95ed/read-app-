import '../entities/reader_settings.dart';
import '../repositories/pdf_repository.dart';

class ScrollModeUseCase {
  final IPdfRepository repository;

  const ScrollModeUseCase(this.repository);

  Future<ReaderScrollMode> getMode() {
    return repository.getScrollMode();
  }

  Future<bool> saveMode(ReaderScrollMode mode) {
    return repository.saveScrollMode(mode);
  }
}

