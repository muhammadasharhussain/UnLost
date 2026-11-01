// lib/providers/reviews_provider.dart
import 'package:flutter/material.dart';
import '../data/models/review_model.dart';
import '../data/repositories/app_repository.dart';

/// Reviews are display-only in this phase: they never change trust scores.
class ReviewsProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ReviewModel> _reunions = [];
  List<ReviewModel> _allReviews = [];
  final Map<String, List<ReviewModel>> _byUser = {};
  final Map<String, bool> _reviewedCases = {};

  bool _isLoadingReunions = false;
  bool _isLoadingAll = false;
  String? _errorMessage;

  ReviewsProvider(this._repository) {
    loadReunions();
  }

  List<ReviewModel> get reunions => _reunions;
  List<ReviewModel> get allReviews => _allReviews;
  bool get isLoadingReunions => _isLoadingReunions;
  bool get isLoadingAll => _isLoadingAll;
  String? get errorMessage => _errorMessage;

  List<ReviewModel> reviewsFor(String userId) => _byUser[userId] ?? const [];

  double averageFor(String userId) {
    final list = reviewsFor(userId);
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (a, r) => a + r.rating);
    return sum / list.length;
  }

  Future<void> loadReunions() async {
    _isLoadingReunions = true;
    notifyListeners();
    try {
      _reunions = await _repository.getRecentReunions();
    } catch (_) {
      // The strip is optional. Stay quiet when it cannot load.
      _reunions = [];
    }
    _isLoadingReunions = false;
    notifyListeners();
  }

  final Map<String, bool> _loadingUsers = {};
  final Map<String, String?> _userErrors = {};

  bool isUserLoading(String userId) => _loadingUsers[userId] ?? false;
  String? userError(String userId) => _userErrors[userId];

  Future<void> loadForUser(String userId) async {
    _loadingUsers[userId] = true;
    _userErrors[userId] = null;
    notifyListeners();
    try {
      _byUser[userId] = await _repository.getReviewsForUser(userId);
    } catch (e) {
      _userErrors[userId] = e.toString().replaceAll('Exception: ', '');
      _byUser[userId] = _byUser[userId] ?? [];
    }
    _loadingUsers[userId] = false;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoadingAll = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allReviews = await _repository.getAllReviewsAdmin();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    _isLoadingAll = false;
    notifyListeners();
  }

  /// Whether this viewer already reviewed this case. Cached per viewer and case.
  Future<bool> hasReviewed(String caseId, {required String viewerId}) async {
    final key = '$viewerId::$caseId';
    final cached = _reviewedCases[key];
    if (cached != null) return cached;
    try {
      final done = await _repository.hasReviewedCase(caseId);
      _reviewedCases[key] = done;
      return done;
    } catch (_) {
      return false;
    }
  }

  /// Returns null on success, or a readable error message.
  Future<String?> submit({
    required String viewerId,
    required String caseId,
    required String aboutUserId,
    required int rating,
    required String outcome,
    List<String> tags = const [],
    String comment = '',
  }) async {
    try {
      await _repository.submitReview(
        caseId: caseId,
        aboutUserId: aboutUserId,
        rating: rating,
        outcome: outcome,
        tags: tags,
        comment: comment.trim(),
      );
      _reviewedCases['$viewerId::$caseId'] = true;
      // Refresh whatever is on screen.
      await Future.wait([
        loadReunions(),
        loadForUser(aboutUserId),
      ]);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

}
