// lib/data/repositories/mock_app_repository.dart
import 'dart:math';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../models/chat_message_model.dart';
import '../../core/constants/categories.dart';
import 'app_repository.dart';
import 'seed_data.dart';

class MockAppRepository implements AppRepository {
  final Random _random = Random();

  late List<UserModel> _users;
  late List<ItemModel> _items;
  late List<ClaimModel> _claims;
  late List<ChatMessageModel> _chatMessages;
  UserModel? _currentUser;

  bool _simulateErrors = false;

  @override
  bool get simulateErrors => _simulateErrors;

  @override
  set simulateErrors(bool value) {
    _simulateErrors = value;
  }

  MockAppRepository() {
    _users = List.from(SeedData.initialUsers);
    _items = List.from(SeedData.initialItems);
    _claims = List.from(SeedData.initialClaims);
    _chatMessages = List.from(SeedData.initialChatMessages);
    // Default logged in user is Terry Melton (regular student with high trust)
    _currentUser = SeedData.userTerry;
  }

  Future<void> _simulateDelay() async {
    final ms = 400 + _random.nextInt(450); // 400ms - 850ms
    await Future.delayed(Duration(milliseconds: ms));
    if (_simulateErrors) {
      throw Exception(
        'Simulated network failure. Flaky error mode is enabled in Demo Settings. Tap retry to test recovery.',
      );
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _simulateDelay();

    // Strict rule: Sign up is student ONLY. No admin accounts can be registered.
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: 'student', // Never admin
      trustScore: 50, // Starting baseline
      itemsReturned: 0,
      itemsRecovered: 0,
      token: 'token_${DateTime.now().millisecondsSinceEpoch}',
    );

    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await _simulateDelay();

    // Check seeded users
    final found = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () {
        // Fallback for custom demo login
        final u = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email.trim(),
          phone: '+1 (555) 012-7890',
          role: 'student',
          trustScore: 55,
          token: 'token_custom',
        );
        _users.add(u);
        return u;
      },
    );

    _currentUser = found;
    return found;
  }

  @override
  Future<UserModel?> me() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<List<ItemModel>> getItems({
    String? type,
    String? category,
    String? search,
  }) async {
    await _simulateDelay();

    return _items.where((item) {
      // ONLY approved/active items are visible on public browse!
      // Pending review, rejected, or hidden items are NOT public.
      final isPublic = item.isActive || item.isHandoverPending;
      if (!isPublic) return false;

      if (type != null && type.isNotEmpty && item.type != type) {
        return false;
      }
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'all' &&
          item.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchDesc = item.description.toLowerCase().contains(query);
        final matchArea = item.area.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchArea) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ItemModel> getItemById(String id) async {
    await _simulateDelay();
    return _items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('Item not found with id $id'),
    );
  }

  @override
  Future<List<String>> getQuestions(String itemId) async {
    await _simulateDelay();
    final item = await getItemById(itemId);
    return ItemCategories.getQuestionsForCategory(item.category);
  }

  @override
  Future<List<ItemModel>> getMyItems() async {
    await _simulateDelay();
    if (_currentUser == null) return [];
    return _items
        .where((i) => i.posterId == _currentUser!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ItemModel> createItem({
    required String type,
    required String title,
    required String category,
    required String description,
    required String area,
    required DateTime dateTime,
    List<String>? hiddenFields,
  }) async {
    await _simulateDelay();
    final user = _currentUser ?? SeedData.userTerry;

    if (user.role == 'admin') {
      throw Exception('Campus administrators are reviewers only and cannot create posts.');
    }

    // Core rule: both found and lost posts ALWAYS start in pending_review
    final newItem = ItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      category: category,
      description: description,
      area: area,
      dateTime: dateTime,
      hiddenFields: hiddenFields ?? const [],
      status: 'pending_review', // Admin must approve before public feed
      posterId: user.id,
      posterName: user.name,
      posterTrustScore: user.trustScore,
      createdAt: DateTime.now(),
    );

    _items.insert(0, newItem);
    return newItem;
  }

  @override
  Future<ClaimModel> submitClaim({
    required String itemId,
    required List<String> answers,
  }) async {
    await _simulateDelay();
    final user = _currentUser ?? SeedData.userTerry;

    if (user.role == 'admin') {
      throw Exception('Campus administrators are reviewers only and cannot submit claims.');
    }

    final item = _items.firstWhere((i) => i.id == itemId);

    // Compute mock match score for admin & finder review
    final int score = 75 + _random.nextInt(23); // 75 - 97
    final bool isHighVal = ItemCategories.isHighValueCategory(item.category);

    // Core rule: Always starts as awaiting_admin before finder sees it
    final newClaim = ClaimModel(
      id: 'claim_${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      itemTitle: item.title,
      itemCategory: item.category,
      claimantId: user.id,
      claimantName: user.name,
      claimantTrustScore: user.trustScore,
      answers: answers,
      finderAnswers: item.hiddenFields,
      matchScore: score, // Kept internal / never shown to claimant
      status: 'awaiting_admin', // Goes to admin queue first!
      isHighValue: isHighVal,
      createdAt: DateTime.now(),
    );

    _claims.insert(0, newClaim);
    return newClaim;
  }

  @override
  Future<List<ClaimModel>> getMyClaims() async {
    await _simulateDelay();
    if (_currentUser == null) return [];
    return _claims
        .where((c) => c.claimantId == _currentUser!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ClaimModel>> getClaimsForItem(String itemId) async {
    await _simulateDelay();
    // Finder only sees claims that have passed admin review
    // Finder NEVER receives or sees the handover OTP code
    return _claims.where((c) {
      return c.itemId == itemId &&
          (c.status == 'passed_to_finder' ||
              c.status == 'approved' ||
              c.status == 'handover_pending' ||
              c.status == 'resolved' ||
              c.status == 'rejected' ||
              c.status == 'rejected_fake');
    }).map((c) => c.copyWith(clearHandoverOtp: true)).toList()
      // Ranked recommendation: highest match score first!
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  @override
  Future<ClaimModel> approveClaim(String claimId) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final claim = _claims[index];
    final isHighVal = claim.isHighValue;

    // Generate 6-digit OTP for high-value handover
    final String otp = (100000 + _random.nextInt(900000)).toString();

    final updatedClaim = claim.copyWith(
      status: isHighVal ? 'handover_pending' : 'approved',
      handoverOtp: isHighVal ? otp : null,
    );
    _claims[index] = updatedClaim;

    // Update item status
    final itemIdx = _items.indexWhere((i) => i.id == claim.itemId);
    if (itemIdx != -1) {
      _items[itemIdx] = _items[itemIdx].copyWith(
        status: isHighVal ? 'handover_pending' : 'resolved',
      );
    }

    // Finder screen receives the approved claim without the OTP code
    return updatedClaim.copyWith(clearHandoverOtp: true);
  }

  @override
  Future<ClaimModel> rejectClaim(String claimId, {String? reason}) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final updatedClaim = _claims[index].copyWith(
      status: 'rejected',
      rejectionReason: reason ?? 'Answers did not match verification details.',
    );
    _claims[index] = updatedClaim;
    return updatedClaim;
  }

  @override
  Future<ClaimModel> reportFake(String claimId, {String? reason}) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final claim = _claims[index];
    final updatedClaim = claim.copyWith(
      status: 'rejected_fake',
      rejectionReason:
          reason ?? 'Reported as fraudulent or deceptive claim.',
    );
    _claims[index] = updatedClaim;

    // Dock claimant's trust score by 15 points
    final userIdx = _users.indexWhere((u) => u.id == claim.claimantId);
    if (userIdx != -1) {
      final currentScore = _users[userIdx].trustScore;
      _users[userIdx] = _users[userIdx].copyWith(
        trustScore: max(5, currentScore - 15),
      );
    }

    return updatedClaim;
  }

  @override
  Future<ClaimModel> confirmHandover(String claimId, String otp) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final claim = _claims[index];
    if (claim.handoverOtp != null && claim.handoverOtp != otp.trim()) {
      throw Exception(
        'Invalid 6-digit handover code. Please ask claimant to re-read code aloud.',
      );
    }

    final updatedClaim = claim.copyWith(status: 'resolved');
    _claims[index] = updatedClaim;

    // Update item status to resolved
    final itemIdx = _items.indexWhere((i) => i.id == claim.itemId);
    if (itemIdx != -1) {
      _items[itemIdx] = _items[itemIdx].copyWith(status: 'resolved');
    }

    // Reward both users trust points
    final finderIdx = _users.indexWhere((u) => u.id == _currentUser?.id);
    if (finderIdx != -1) {
      _users[finderIdx] = _users[finderIdx].copyWith(
        trustScore: min(100, _users[finderIdx].trustScore + 6),
        itemsReturned: _users[finderIdx].itemsReturned + 1,
      );
    }

    final claimantIdx = _users.indexWhere((u) => u.id == claim.claimantId);
    if (claimantIdx != -1) {
      _users[claimantIdx] = _users[claimantIdx].copyWith(
        trustScore: min(100, _users[claimantIdx].trustScore + 4),
        itemsRecovered: _users[claimantIdx].itemsRecovered + 1,
      );
    }

    return updatedClaim;
  }

  @override
  Future<ChatMessageModel> sendMessage(String claimId, String text) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final user = _currentUser ?? SeedData.userTerry;

    if (user.role == 'admin') {
      throw Exception('Campus administrators are reviewers only and cannot participate in direct chat.');
    }

    final msg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      senderId: user.id,
      senderName: user.name,
      text: text,
      timestamp: DateTime.now(),
    );

    _chatMessages.add(msg);
    return msg;
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String claimId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _chatMessages
        .where((m) => m.claimId == claimId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // ── Admin-Only Methods ──────────────────────────────────────────────────────
  @override
  Future<List<ItemModel>> getPendingPosts({String? type}) async {
    await _simulateDelay();
    return _items.where((i) {
      final isPending = i.isPendingReview;
      if (!isPending) return false;
      if (type != null && type.isNotEmpty && i.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ItemModel> approvePost(String itemId) async {
    await _simulateDelay();
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');

    final updated = _items[index].copyWith(status: 'active');
    _items[index] = updated;
    return updated;
  }

  @override
  Future<ItemModel> rejectPost(String itemId, String reason) async {
    await _simulateDelay();
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');

    final updated = _items[index].copyWith(
      status: 'rejected',
      rejectionReason: reason,
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<List<ClaimModel>> getPendingClaims() async {
    await _simulateDelay();
    return _claims
        .where((c) => c.status == 'awaiting_admin')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ClaimModel> passClaim(String claimId) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final updated = _claims[index].copyWith(status: 'passed_to_finder');
    _claims[index] = updated;
    return updated;
  }

  @override
  Future<ClaimModel> rejectClaimAdmin(String claimId, String reason) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final updated = _claims[index].copyWith(
      status: 'rejected',
      rejectionReason: reason,
    );
    _claims[index] = updated;
    return updated;
  }

  @override
  Future<ClaimModel> rejectClaimAdminAsFake(
      String claimId, String reason) async {
    await _simulateDelay();
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw Exception('Claim not found');

    final claim = _claims[index];
    final updated = claim.copyWith(
      status: 'rejected_fake',
      rejectionReason: reason,
    );
    _claims[index] = updated;

    // Drop claimant's trust score
    final userIdx = _users.indexWhere((u) => u.id == claim.claimantId);
    if (userIdx != -1) {
      final current = _users[userIdx].trustScore;
      _users[userIdx] = _users[userIdx].copyWith(
        trustScore: max(5, current - 20),
      );
    }

    return updated;
  }
}
