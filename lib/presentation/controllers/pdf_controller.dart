import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/usecases/get_saved_page_usecase.dart';
import '../../domain/usecases/print_pdf_usecase.dart';
import '../../domain/usecases/save_page_usecase.dart';
import '../../domain/usecases/scroll_mode_usecase.dart';
import '../../domain/usecases/share_pdf_usecase.dart';

class PdfReaderController extends ChangeNotifier {
  final GetSavedPageUseCase getSavedPageUseCase;
  final SavePageUseCase savePageUseCase;
  final PrintPdfUseCase printPdfUseCase;
  final SharePdfUseCase sharePdfUseCase;
  final ScrollModeUseCase scrollModeUseCase;

  PdfViewerController pdfViewerController = PdfViewerController();

  BookEntity _currentBook = BookEntity.defaultCatalog().first;
  bool _isReady = false;
  int _initialPageNumber = 1;
  int _currentPage = 1;
  int _totalPages = 0;
  int _savedPage = 1;
  double _zoomLevel = AppConstants.defaultZoom;
  ReaderScrollMode _scrollMode = ReaderScrollMode.verticalContinuous;
  PdfInteractionMode _interactionMode = PdfInteractionMode.pan;
  bool _isLoading = true;
  bool _isPrinting = false;
  bool _isSharing = false;
  String? _errorMessage;
  int? _recentlyRestoredPage;

  // Debounce timer for disk persistence during rapid scrolling
  Timer? _saveDebounceTimer;

  // Search state
  bool _isSearchOpen = false;
  String _searchQuery = '';
  PdfTextSearchResult? _searchResult;
  bool _isSearching = false;
  int _currentSearchIndex = 0;
  int _totalSearchCount = 0;
  bool _hasSearchCompleted = false;

  PdfReaderController({
    required this.getSavedPageUseCase,
    required this.savePageUseCase,
    required this.printPdfUseCase,
    required this.sharePdfUseCase,
    required this.scrollModeUseCase,
  });

  // Getters
  BookEntity get currentBook => _currentBook;
  String get assetPath => _currentBook.assetPath;
  bool get isReady => _isReady;
  int get initialPageNumber => _initialPageNumber;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get savedPage => _savedPage;
  double get zoomLevel => _zoomLevel;
  ReaderScrollMode get scrollMode => _scrollMode;
  PdfInteractionMode get interactionMode => _interactionMode;
  bool get isPanMode => _interactionMode == PdfInteractionMode.pan;
  bool get isLoading => _isLoading;
  bool get isPrinting => _isPrinting;
  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;
  int? get recentlyRestoredPage => _recentlyRestoredPage;

  // Search Getters
  bool get isSearchOpen => _isSearchOpen;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  int get currentSearchIndex => _currentSearchIndex;
  int get totalSearchCount => _totalSearchCount;
  bool get hasSearchCompleted => _hasSearchCompleted;

  PdfScrollDirection get pdfScrollDirection {
    return _scrollMode == ReaderScrollMode.verticalContinuous
        ? PdfScrollDirection.vertical
        : PdfScrollDirection.horizontal;
  }

  PdfPageLayoutMode get pdfPageLayoutMode {
    return _scrollMode == ReaderScrollMode.singlePage
        ? PdfPageLayoutMode.single
        : PdfPageLayoutMode.continuous;
  }

  /// Opens a specific book (Reading or Activity) and loads its saved reading position
  Future<void> openBook(BookEntity book) async {
    _saveDebounceTimer?.cancel();
    _detachSearchResult();

    // Reset controller cleanly for the new book
    pdfViewerController.dispose();
    pdfViewerController = PdfViewerController();

    _currentBook = book;
    _isReady = false;
    _isLoading = true;
    _errorMessage = null;
    _totalPages = 0;
    _zoomLevel = AppConstants.defaultZoom;
    _recentlyRestoredPage = null;
    _isSearchOpen = false;
    _searchQuery = '';
    _isSearching = false;
    _currentSearchIndex = 0;
    _totalSearchCount = 0;
    _hasSearchCompleted = false;
    notifyListeners();

    try {
      final results = await Future.wait([
        getSavedPageUseCase.execute(book.assetPath),
        scrollModeUseCase.getMode(),
      ]);
      _savedPage = results[0] as int;
      _scrollMode = results[1] as ReaderScrollMode;
    } catch (_) {
      _savedPage = 1;
      _scrollMode = ReaderScrollMode.verticalContinuous;
    }

    _initialPageNumber = _savedPage > 0 ? _savedPage : 1;
    _currentPage = _initialPageNumber;
    _isReady = true;
    notifyListeners();
  }

  /// Document loaded handler
  void onDocumentLoaded(PdfDocumentLoadedDetails details) {
    _totalPages = details.document.pages.count;
    _isLoading = false;
    _errorMessage = null;

    if (_savedPage > 1 && _savedPage <= _totalPages) {
      _recentlyRestoredPage = _savedPage;
    }

    notifyListeners();
  }

  /// Page changed handler (debounces disk persistence for smooth scrolling)
  void onPageChanged(int newPageNumber) {
    if (_currentPage == newPageNumber) return;
    _currentPage = newPageNumber;
    _savedPage = newPageNumber;
    notifyListeners();

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      savePageUseCase.execute(_currentBook.assetPath, newPageNumber);
    });
  }

  /// Immediately persist current page (called on jump, close, or dispose)
  Future<void> flushSave() async {
    _saveDebounceTimer?.cancel();
    if (_totalPages > 0 && _currentPage >= 1 && _currentPage <= _totalPages) {
      await savePageUseCase.execute(_currentBook.assetPath, _currentPage);
    }
  }

  /// Clear the recently restored page notice
  void clearRestoredNotice() {
    if (_recentlyRestoredPage == null) return;
    _recentlyRestoredPage = null;
    notifyListeners();
  }

  /// Jump directly to a specific page
  bool jumpToPage(int targetPage) {
    if (_totalPages <= 0) return false;
    if (targetPage < 1 || targetPage > _totalPages) return false;

    try {
      pdfViewerController.jumpToPage(targetPage);
      _currentPage = targetPage;
      _savedPage = targetPage;
      _saveDebounceTimer?.cancel();
      savePageUseCase.execute(_currentBook.assetPath, targetPage);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Navigate to previous page smoothly
  void previousPage() {
    if (_currentPage > 1) {
      jumpToPage(_currentPage - 1);
    }
  }

  /// Navigate to next page smoothly
  void nextPage() {
    if (_currentPage < _totalPages) {
      jumpToPage(_currentPage + 1);
    }
  }

  /// Sync zoom level from viewer pinch / double-tap without triggering a feedback loop
  void syncZoomFromViewer(double newZoom) {
    final clamped = newZoom.clamp(AppConstants.minZoom, AppConstants.maxZoom);
    if ((clamped - _zoomLevel).abs() > 0.01) {
      _zoomLevel = clamped;
      notifyListeners();
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

  /// Set scroll mode explicitly and persist it
  void setScrollMode(ReaderScrollMode mode) {
    if (_scrollMode == mode) return;
    _scrollMode = mode;
    _initialPageNumber = _currentPage;
    scrollModeUseCase.saveMode(mode);
    notifyListeners();
  }

  /// Cycle through smooth scroll modes
  void cycleScrollMode() {
    final values = ReaderScrollMode.values;
    final nextIndex = (values.indexOf(_scrollMode) + 1) % values.length;
    setScrollMode(values[nextIndex]);
  }

  /// Toggle interaction mode between smooth pan (hand) and text selection
  void toggleInteractionMode() {
    _interactionMode = _interactionMode == PdfInteractionMode.pan
        ? PdfInteractionMode.selection
        : PdfInteractionMode.pan;
    if (_interactionMode == PdfInteractionMode.pan) {
      pdfViewerController.clearSelection();
    }
    notifyListeners();
  }

  // ==================== In-Book Search Logic ====================

  void toggleSearch() {
    _isSearchOpen = !_isSearchOpen;
    if (!_isSearchOpen) {
      clearSearch();
    } else {
      notifyListeners();
    }
  }

  void performSearch(String query) {
    final trimmed = query.trim();
    _searchQuery = trimmed;

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    _detachSearchResult();
    _isSearching = true;
    _hasSearchCompleted = false;
    _currentSearchIndex = 0;
    _totalSearchCount = 0;
    notifyListeners();

    _searchResult = pdfViewerController.searchText(trimmed);
    _searchResult?.addListener(_onSearchResultChanged);
  }

  void _onSearchResultChanged() {
    final result = _searchResult;
    if (result == null) return;

    _totalSearchCount = result.totalInstanceCount;
    _currentSearchIndex = result.currentInstanceIndex;
    _hasSearchCompleted = result.isSearchCompleted;
    if (result.isSearchCompleted || result.totalInstanceCount > 0) {
      _isSearching = false;
    }
    notifyListeners();
  }

  void nextSearchMatch() {
    if (_searchResult != null && _totalSearchCount > 0) {
      _searchResult!.nextInstance();
    }
  }

  void previousSearchMatch() {
    if (_searchResult != null && _totalSearchCount > 0) {
      _searchResult!.previousInstance();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _currentSearchIndex = 0;
    _totalSearchCount = 0;
    _hasSearchCompleted = false;
    _detachSearchResult();
    notifyListeners();
  }

  void _detachSearchResult() {
    if (_searchResult != null) {
      _searchResult!.removeListener(_onSearchResultChanged);
      _searchResult!.clear();
      _searchResult = null;
    }
  }

  // ==================== Print & Share ====================

  /// Print current book
  Future<bool> printDocument({required String documentName}) async {
    if (_isPrinting) return false;
    _isPrinting = true;
    notifyListeners();

    try {
      final success = await printPdfUseCase.execute(
        assetPath: _currentBook.assetPath,
        documentName: documentName,
      );
      _isPrinting = false;
      notifyListeners();
      return success;
    } catch (_) {
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  /// Share current book via Bluetooth, Messaging apps (WhatsApp, Telegram, etc.)
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
        assetPath: _currentBook.assetPath,
        subject: subject,
        text: text,
        fileName: _currentBook.fileName,
        sharePositionOrigin: sharePositionOrigin,
      );
      _isSharing = false;
      notifyListeners();
      return success;
    } catch (_) {
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
    _saveDebounceTimer?.cancel();
    _detachSearchResult();
    pdfViewerController.dispose();
    super.dispose();
  }
}
