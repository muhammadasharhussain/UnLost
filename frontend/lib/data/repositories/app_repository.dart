// lib/data/repositories/app_repository.dart
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../models/chat_message_model.dart';

/// The typed API contract for Unlost.
/// Both MockAppRepository and future HttpAppRepository implement this interface identically.
abstract class AppRepository {
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel?> me();

  Future<void> logout();

  Future<List<ItemModel>> getItems({
    String? type,
    String? category,
    String? search,
  });

  Future<ItemModel> getItemById(String id);

  Future<List<String>> getQuestions(String itemId);

  Future<List<ItemModel>> getMyItems();

  Future<ItemModel> createItem({
    required String type,
    required String title,
    required String category,
    required String description,
    required String area,
    required DateTime dateTime,
    List<String>? hiddenFields,
  });

  Future<ClaimModel> submitClaim({
    required String itemId,
    required List<String> answers,
  });

  Future<List<ClaimModel>> getMyClaims();

  Future<List<ClaimModel>> getClaimsForItem(String itemId);

  Future<ClaimModel> approveClaim(String claimId);

  Future<ClaimModel> rejectClaim(String claimId, {String? reason});

  Future<ClaimModel> reportFake(String claimId, {String? reason});

  Future<ClaimModel> confirmHandover(String claimId, String otp);

  Future<ChatMessageModel> sendMessage(String claimId, String text);

  Future<List<ChatMessageModel>> getMessages(String claimId);

  // Admin-only (role must be admin; UI must never expose these to a student account)
  Future<List<ItemModel>> getPendingPosts({String? type});

  Future<ItemModel> approvePost(String itemId);

  Future<ItemModel> rejectPost(String itemId, String reason);

  Future<List<ClaimModel>> getPendingClaims();

  Future<ClaimModel> passClaim(String claimId);

  Future<ClaimModel> rejectClaimAdmin(String claimId, String reason);

  Future<ClaimModel> rejectClaimAdminAsFake(String claimId, String reason);

  // Developer / Demo mode toggles
  bool get simulateErrors;
  set simulateErrors(bool value);
}
