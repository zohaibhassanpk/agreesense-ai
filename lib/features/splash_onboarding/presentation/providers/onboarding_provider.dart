import 'package:flutter/material.dart';
import '../../../../core/services/local_storage/local_storage_service.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/onboarding_page_entity.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// State notifier for managing onboarding flow.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    required this.repository,
    required this.localStorageService,
  });

  final OnboardingRepository repository;
  final LocalStorageService localStorageService;
  final LoggerService _logger = LoggerService(className: 'OnboardingProvider');

  List<OnboardingPageEntity> _pages = [];
  int _currentPageIndex = 0;
  bool _isLoading = true;

  /// All onboarding pages.
  List<OnboardingPageEntity> get pages => _pages;

  /// Current page index in the onboarding sequence.
  int get currentPageIndex => _currentPageIndex;

  /// Current onboarding page.
  OnboardingPageEntity? get currentPage =>
      _currentPageIndex < _pages.length ? _pages[_currentPageIndex] : null;

  /// Total number of pages.
  int get totalPages => _pages.length;

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Whether there is a next page.
  bool get hasNextPage => _currentPageIndex < _pages.length - 1;

  /// Whether there is a previous page.
  bool get hasPreviousPage => _currentPageIndex > 0;

  /// Initializes the onboarding data.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pages = await repository.getAllPages();
      _currentPageIndex = 0;
    } catch (_) {
      _pages = [];
      _currentPageIndex = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Moves to the next page.
  void nextPage() {
    if (hasNextPage) {
      _currentPageIndex++;
      notifyListeners();
    }
  }

  /// Moves to the previous page.
  void previousPage() {
    if (hasPreviousPage) {
      _currentPageIndex--;
      notifyListeners();
    }
  }

  /// Goes to a specific page by index.
  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// Resets to the first page.
  void reset() {
    _currentPageIndex = 0;
    notifyListeners();
  }

  /// Marks onboarding as completed for future app launches.
  Future<void> markOnboardingCompleted() async {
    try {
      await localStorageService.saveOnboardingCompleted(true);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to persist onboarding completion.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
