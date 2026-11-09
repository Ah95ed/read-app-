import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/usecases/get_saved_page_usecase.dart';
import '../../domain/usecases/print_pdf_usecase.dart';
import '../../domain/usecases/save_page_usecase.dart';
import '../../domain/usecases/share_pdf_usecase.dart';

class PdfReaderController extends ChangeNotifier {
  final GetSavedPageUseCase getSavedPageUseCase;
  final SavePageUseCase savePageUseCase;
  final PrintPdfUseCase printPdfUseCase;
  final SharePdfUseCase sharePdfUseCase;
  final String assetPath;

  late final PdfViewerController pdfViewerController;

  int _currentPage = 1;
  int _totalPages = 0;
  int _savedPage = 1;
  double _zoomLevel = AppConstants.defaultZoom;
  bool _isVerticalScroll = true;
  bool _isLoading = true;
  bool _isPrinting = false;
  bool _isSharing = false;
  String? _errorMessage;
  bool _hasRestoredLastPage = false;
  int? _recentlyRestoredPage;

  PdfReaderController({
    required this.getSavedPageUseCase,
    required this.savePageUseCase,
    required this.printPdfUseCase,
    required this.sharePdfUseCase,
    this.assetPath = AppConstants.defaultPdfAsset,
  }) {
    pdfViewerController = PdfViewerController();
    _loadInitialState();
  }

  // Getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get savedPage => _savedPage;
  double get zoomLevel => _zoomLevel;
  bool get isVerticalScroll => _isVerticalScroll;
  bool get isLoading => _isLoading;
  bool get isPrinting => _isPrinting;
  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;
  int? get recentlyRestoredPage => _recentlyRestoredPage;

  Future<void> _loadInitialState() async {
    try {
      _savedPage = await getSavedPageUseCase.execute(assetPath);
      _currentPage = _savedPage > 0 ? _savedPage : 1;
    } catch (_) {
      _savedPage = 1;
      _currentPage = 1;
    }
    notifyListeners();
  }

  /// Document loaded handler
  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    _totalPages = details.document.pages.count;
    _isLoading = false;
    _errorMessage = null;

    // Restore saved page if greater than 1
    if (_savedPage > 1 && _savedPage <= _totalPages && !_hasRestoredLastPage) {
      _hasRestoredLastPage = true;
      _recentlyRestoredPage = _savedPage;
      // Slight delay to ensure SfPdfViewer layout is ready for jumping
      Future.microtask(() {
        jumpToPage(_savedPage);
      });
    }

    notifyListeners();
  }

  /// Page changed handler
  void onPageChanged(int newPageNumber) {
    if (_currentPage == newPageNumber) return;
    _currentPage = newPageNumber;
    _savedPage = newPageNumber;
    savePageUseCase.execute(assetPath, newPageNumber);
    notifyListeners();
  }

  /// Clear the recently restored page notice
  void clearRestoredNotice() {
    _recentlyRestoredPage = null;
    notifyListeners();
  }

  /// Jump directly to a specific page
  bool jumpToPage(int targetPage) {
    if (_totalPages <= 0) {
      // Document not loaded yet
      return false;
    }

    if (targetPage < 1 || targetPage > _totalPages) {
      return false;
    }

    try {
      pdfViewerController.jumpToPage(targetPage);
      _currentPage = targetPage;
      _savedPage = targetPage;
      savePageUseCase.execute(assetPath, targetPage);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Increase zoom level
  void zoomIn() {
    final nextZoom = (_zoomLevel + AppConstants.zoomStep).clamp(
      AppConstants.minZoom,
      AppConstants.maxZoom,
    );
    if (nextZoom != _zoomLevel) {
      _zoomLevel = nextZoom;
      pdfViewerController.zoomLevel = _zoomLevel;
      notifyListeners();
    }
  }

  /// Decrease zoom level
  void zoomOut() {
    final nextZoom = (_zoomLevel - AppConstants.zoomStep).clamp(
      AppConstants.minZoom,
      AppConstants.maxZoom,
    );
    if (nextZoom != _zoomLevel) {
      _zoomLevel = nextZoom;
      pdfViewerController.zoomLevel = _zoomLevel;
      notifyListeners();
    }
  }

  /// Reset zoom level to 100%
  void resetZoom() {
    _zoomLevel = AppConstants.defaultZoom;
    pdfViewerController.zoomLevel = AppConstants.defaultZoom;
    notifyListeners();
  }

  /// Toggle between vertical continuous scroll and horizontal page view
  void toggleScrollDirection() {
    _isVerticalScroll = !_isVerticalScroll;
    notifyListeners();
  }

  /// Set scroll direction explicitly
  void setScrollDirection(bool isVertical) {
    if (_isVerticalScroll == isVertical) return;
    _isVerticalScroll = isVertical;
    notifyListeners();
  }

  /// Print document
  Future<bool> printDocument({String documentName = 'Book_IQ_Document'}) async {
    if (_isPrinting) return false;
    _isPrinting = true;
    notifyListeners();

    try {
      final success = await printPdfUseCase.execute(
        assetPath: assetPath,
        documentName: documentName,
      );
      _isPrinting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  /// Share document via Bluetooth, Messaging apps (WhatsApp, Telegram, etc.)
  Future<bool> shareDocument({
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    if (_isSharing) return false;
    _isSharing = true;
    notifyListeners();

    try {
      final success = await sharePdfUseCase.execute(
        assetPath: assetPath,
        subject: subject,
        text: text,
        fileName: 'c1_book.pdf',
        sharePositionOrigin: sharePositionOrigin,
      );
      _isSharing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isSharing = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle document loading failure
  void onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    _isLoading = false;
    _errorMessage = details.error;
    notifyListeners();
  }

  @override
  void dispose() {
    pdfViewerController.dispose();
    super.dispose();
  }
}
