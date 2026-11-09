import 'package:flutter/material.dart';
import '../repositories/pdf_repository.dart';

class SharePdfUseCase {
  final IPdfRepository repository;

  const SharePdfUseCase(this.repository);

  Future<bool> execute({
    required String assetPath,
    String? subject,
    String? text,
    String fileName = 'book.pdf',
    Rect? sharePositionOrigin,
  }) {
    return repository.shareDocument(
      assetPath: assetPath,
      subject: subject,
      text: text,
      fileName: fileName,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

