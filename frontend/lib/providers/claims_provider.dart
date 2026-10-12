// lib/providers/claims_provider.dart
import 'package:flutter/material.dart';
import '../data/models/claim_model.dart';
import '../data/repositories/app_repository.dart';

class ClaimsProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ClaimModel> _myClaims = [];
  List<ClaimModel> _itemClaims = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClaimModel> get myClaims => _myClaims;
  List<ClaimModel> get itemClaims => _itemClaims;
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
