// lib/providers/claims_provider.dart
import 'package:flutter/material.dart';
import '../data/models/claim_model.dart';
import '../data/models/item_model.dart';
import '../data/repositories/app_repository.dart';

class ClaimsProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ClaimModel> _myClaims = [];
  List<ClaimModel> _itemClaims = [];

  /// Claims on the viewer's OWN posts (what the owner is allowed to see),
  /// keyed by item id. Used by My Activity for progress and finder-claim review.
  final Map<String, List<ClaimModel>> _claimsByMyItem = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<ClaimModel> get myClaims => _myClaims;
  List<ClaimModel> get itemClaims => _itemClaims;
  Map<String, List<ClaimModel>> get claimsByMyItem => _claimsByMyItem;

  List<ClaimModel> claimsOnMyItem(String itemId) =>
      _claimsByMyItem[itemId] ?? const [];

  /// Finder claims on one of my LOST posts that the admin passed and that wait
  /// for my "This is mine / Not mine" answer.
  List<ClaimModel> finderClaimsAwaitingMe(String itemId) => claimsOnMyItem(itemId)
      .where((c) => c.status == 'passed_to_finder')
      .toList();

  int get totalFinderClaimsAwaitingOwner {
    int total = 0;
    for (final claims in _claimsByMyItem.values) {
      total += claims.where((c) => c.status == 'passed_to_finder').length;
    }
    return total;
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ClaimsProvider(this._repository) {
    loadMyClaims();
  }

  Future<void> loadMyClaims() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myClaims = await _repository.getMyClaims();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadClaimsForItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itemClaims = await _repository.getClaimsForItem(itemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads claims for each of the viewer's own posts that are past admin review.
  Future<void> loadClaimsForMyItems(List<ItemModel> myItems) async {
    final eligible = myItems.where((i) => !i.isPendingReview && !i.isRejected);
    final results = <String, List<ClaimModel>>{};
    await Future.wait(eligible.map((item) async {
      try {
        results[item.id] = await _repository.getClaimsForItem(item.id);
      } catch (_) {
        // Keep whatever we had for this item.
        results[item.id] = _claimsByMyItem[item.id] ?? const [];
      }
    }));
    _claimsByMyItem
      ..clear()
      ..addAll(results);
    notifyListeners();
  }

  /// A finder says "I found this" on someone's LOST report.
  Future<ClaimModel?> submitFinderClaim({
    required String itemId,
    required String foundDescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final claim = await _repository.submitFinderClaim(
        itemId: itemId,
        foundDescription: foundDescription,
      );
      _isLoading = false;
      await loadMyClaims();
      return claim;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// The owner answers "This is mine" (isMine) or "Not mine".
  Future<bool> confirmFinderClaim({
    required String claimId,
    required bool isMine,
  }) async {
    _errorMessage = null;
    try {
      final updated = await _repository.confirmFinderClaim(
        claimId: claimId,
        isMine: isMine,
      );
      // Patch every cache that holds this claim.
      final list = _claimsByMyItem[updated.itemId];
      if (list != null) {
        _claimsByMyItem[updated.itemId] =
            list.map((c) => c.id == claimId ? updated : c).toList();
      }
      final idx = _itemClaims.indexWhere((c) => c.id == claimId);
      if (idx != -1) _itemClaims[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<ClaimModel?> submitClaim({
    required String itemId,
    required List<String> answers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final claim = await _repository.submitClaim(
        itemId: itemId,
        answers: answers,
      );
      _isLoading = false;
      await loadMyClaims();
      return claim;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> approveClaim(String claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.approveClaim(claimId);
      final idx = _itemClaims.indexWhere((c) => c.id == claimId);
      if (idx != -1) {
        _itemClaims[idx] = updated;
      }
      // CRITICAL: also refresh the claimant's own list so the handover OTP
      // is visible in My Claims as soon as the finder approves — even when
      // MyActivityScreen is kept alive inside an IndexedStack.
      await loadMyClaims();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectClaim(String claimId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.rejectClaim(claimId, reason: reason);
      final idx = _itemClaims.indexWhere((c) => c.id == claimId);
      if (idx != -1) {
        _itemClaims[idx] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportFake(String claimId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.reportFake(claimId, reason: reason);
      final idx = _itemClaims.indexWhere((c) => c.id == claimId);
      if (idx != -1) {
        _itemClaims[idx] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmHandover(String claimId, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.confirmHandover(claimId, otp);
      final idx = _itemClaims.indexWhere((c) => c.id == claimId);
      if (idx != -1) {
        _itemClaims[idx] = updated;
      }
      await loadMyClaims();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
