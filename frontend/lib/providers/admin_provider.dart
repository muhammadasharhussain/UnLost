// lib/providers/admin_provider.dart
import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/models/claim_model.dart';
import '../data/repositories/app_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ItemModel> _pendingPosts = [];
  List<ClaimModel> _pendingClaims = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _postTypeFilter = 'all'; // 'all' | 'found' | 'lost'

  List<ItemModel> get pendingPosts {
    if (_postTypeFilter == 'all') return _pendingPosts;
    return _pendingPosts.where((p) => p.type == _postTypeFilter).toList();
  }

  List<ClaimModel> get pendingClaims => _pendingClaims;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get postTypeFilter => _postTypeFilter;

  AdminProvider(this._repository) {
    loadAdminData();
  }

  void setPostTypeFilter(String filter) {
    _postTypeFilter = filter;
    notifyListeners();
  }

  Future<void> loadAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final postsFuture = _repository.getPendingPosts();
      final claimsFuture = _repository.getPendingClaims();
      final results = await Future.wait([postsFuture, claimsFuture]);

      _pendingPosts = results[0] as List<ItemModel>;
      _pendingClaims = results[1] as List<ClaimModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approvePost(String itemId) async {
    try {
      await _repository.approvePost(itemId);
      _pendingPosts.removeWhere((p) => p.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectPost(String itemId, String reason) async {
    try {
      await _repository.rejectPost(itemId, reason);
      _pendingPosts.removeWhere((p) => p.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> passClaim(String claimId) async {
    try {
      await _repository.passClaim(claimId);
      _pendingClaims.removeWhere((c) => c.id == claimId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectClaim(String claimId, String reason) async {
    try {
      await _repository.rejectClaimAdmin(claimId, reason);
      _pendingClaims.removeWhere((c) => c.id == claimId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectClaimAsFake(String claimId, String reason) async {
    try {
      await _repository.rejectClaimAdminAsFake(claimId, reason);
      _pendingClaims.removeWhere((c) => c.id == claimId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
