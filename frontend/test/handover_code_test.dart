// test/handover_code_test.dart
//
// Tests for Bug 1 — every approved claim (high-value and low-value alike) must
// produce a 6-digit pickup code visible to the claimant but NOT to the finder.
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/data/repositories/mock_app_repository.dart';

void main() {
  group('Handover OTP — approveClaim (found-post flow)', () {
    late MockAppRepository repo;

    setUp(() {
      repo = MockAppRepository();
    });

    // ── Test 1: non-high-value claim gets a 6-digit code ─────────────────────
    test(
        'Non-high-value claim: finder approves → claimant receives 6-digit code',
        () async {
      // 1. Claimant (Alex) claims a low-value item (keys)
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final submitted = await repo.submitClaim(
        itemId: 'item_f7_keys',
        answers: ['Set of keys with Subaru fob', 'Dorm room 102 tag'],
      );
      expect(submitted.isHighValue, isFalse);
      expect(submitted.handoverOtp, isNull);

      // 2. Admin passes claim
      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(submitted.id);

      // 3. Finder approves
      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final finderResult = await repo.approveClaim(submitted.id);

      // Finder's return value must NOT contain the OTP
      expect(finderResult.handoverOtp, isNull,
          reason: 'Finder must never receive the OTP in the return value');

      // Finder's claims list must also not expose the OTP
      final finderClaims = await repo.getClaimsForItem('item_f7_keys');
      final finderView =
          finderClaims.firstWhere((c) => c.id == submitted.id);
      expect(finderView.handoverOtp, isNull,
          reason: 'Finder claims list must redact the OTP');

      // 4. Claimant can see the OTP via getMyClaims
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final myClaims = await repo.getMyClaims();
      final claimantView =
          myClaims.firstWhere((c) => c.id == submitted.id);

      expect(claimantView.status, equals('handover_pending'));
      expect(claimantView.handoverOtp, isNotNull,
          reason: 'Claimant must receive the pickup code');
      expect(claimantView.handoverOtp!.length, equals(6));
      expect(int.tryParse(claimantView.handoverOtp!), isNotNull,
          reason: 'Code must be exactly 6 decimal digits');
    });

    // ── Test 2: finder never sees the OTP ────────────────────────────────────
    test('Finder never sees the OTP after approving a high-value claim',
        () async {
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final submitted = await repo.submitClaim(
        itemId: 'item_f3_laptop',
        answers: [
          'Dell XPS 15 with GitHub and Python stickers',
          'Black felt zip sleeve with USB-C 130W charger',
        ],
      );
      expect(submitted.isHighValue, isTrue);

      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(submitted.id);

      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final finderResult = await repo.approveClaim(submitted.id);
      expect(finderResult.handoverOtp, isNull);

      final finderClaims = await repo.getClaimsForItem('item_f3_laptop');
      final finderView =
          finderClaims.firstWhere((c) => c.id == submitted.id);
      expect(finderView.handoverOtp, isNull);
    });

    // ── Test 3: wrong code throws ─────────────────────────────────────────────
    test('Wrong handover code fails', () async {
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final submitted = await repo.submitClaim(
        itemId: 'item_f7_keys',
        answers: ['Set of keys with Subaru fob', 'Dorm room 102 tag'],
      );

      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(submitted.id);

      await repo.login(email: 'terry@campus.edu', password: 'password123');
      await repo.approveClaim(submitted.id);

      // Finder tries an obviously wrong code
      expect(
        () => repo.confirmHandover(submitted.id, '000000'),
        throwsA(isA<Exception>()),
        reason: 'Wrong OTP must throw an exception',
      );
    });

    // ── Test 4: correct code resolves the item ───────────────────────────────
    test('Correct handover code resolves the item', () async {
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final submitted = await repo.submitClaim(
        itemId: 'item_f7_keys',
        answers: ['Set of keys with Subaru fob', 'Dorm room 102 tag'],
      );

      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(submitted.id);

      await repo.login(email: 'terry@campus.edu', password: 'password123');
      await repo.approveClaim(submitted.id);

      // Claimant reads the code
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final myClaims = await repo.getMyClaims();
      final otp = myClaims.firstWhere((c) => c.id == submitted.id).handoverOtp!;

      // Finder enters the correct code
      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final resolved = await repo.confirmHandover(submitted.id, otp);
      expect(resolved.status, equals('resolved'));

      // Item is now resolved
      final item = await repo.getItemById('item_f7_keys');
      expect(item.status, equals('resolved'));
    });
  });

  group('Handover OTP — confirmFinderClaim (lost-post finder-claim flow)', () {
    late MockAppRepository repo;

    setUp(() {
      repo = MockAppRepository();
    });

    // ── Test 5: owner says "This is mine" → finder gets code ─────────────────
    test(
        '"This is mine" issues a pickup code to the finder and sets handover_pending',
        () async {
      // Submit a finder-claim on a LOST item (item_l1_sony — Terry's lost earbuds)
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final finderClaim = await repo.submitFinderClaim(
        itemId: 'item_l1_sony',
        foundDescription: 'Silver earbud case near the library entrance',
      );
      expect(finderClaim.status, equals('awaiting_admin'));

      // Admin passes to the owner
      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(finderClaim.id);

      // Owner (Terry) confirms "This is mine"
      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final ownerResult =
          await repo.confirmFinderClaim(claimId: finderClaim.id, isMine: true);

      // Owner (caller) must NOT receive the OTP
      expect(ownerResult.handoverOtp, isNull,
          reason: 'Owner/caller must not receive the OTP');
      expect(ownerResult.status, equals('handover_pending'));

      // Finder (Alex) reads OTP via getMyClaims
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final myFinderClaims = await repo.getMyClaims();
      final finderView =
          myFinderClaims.firstWhere((c) => c.id == finderClaim.id);
      expect(finderView.status, equals('handover_pending'));
      expect(finderView.handoverOtp, isNotNull,
          reason: 'Finder must see the pickup code via getMyClaims');
      expect(finderView.handoverOtp!.length, equals(6));
    });

    // ── Test 6: "Not mine" does not generate a code ───────────────────────────
    test('"Not mine" does not create a handover code', () async {
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final finderClaim = await repo.submitFinderClaim(
        itemId: 'item_l1_sony',
        foundDescription: 'Silver earbud case near the library entrance',
      );

      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(finderClaim.id);

      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final result = await repo.confirmFinderClaim(
          claimId: finderClaim.id, isMine: false);
      expect(result.status, equals('rejected'));
      expect(result.handoverOtp, isNull);
    });
  });
}
