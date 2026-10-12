// test/handover_code_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/data/repositories/mock_app_repository.dart';

void main() {
  group('High-Value Handover Code Flow', () {
    late MockAppRepository repo;

    setUp(() {
      repo = MockAppRepository();
    });

    test('High-value claim: admin passes -> finder approves -> claimant gets 6-digit code & finder does not', () async {
      // 1. Log in as claimant (Alex Chen)
      await repo.login(email: 'alex@campus.edu', password: 'password123');

      // 2. Alex submits a claim on a high-value item (item_f3_laptop - Dell XPS 15)
      final submittedClaim = await repo.submitClaim(
        itemId: 'item_f3_laptop',
        answers: [
          'Dell XPS 15 with GitHub and Python stickers',
          'Black felt zip sleeve with USB-C 130W charger',
        ],
      );

      expect(submittedClaim.isHighValue, isTrue);
      expect(submittedClaim.status, equals('awaiting_admin'));
      expect(submittedClaim.handoverOtp, isNull);

      // 3. Log in as admin and pass the claim to finder
      await repo.login(email: 'admin@campus.edu', password: 'password123');
      final passedClaim = await repo.passClaim(submittedClaim.id);
      expect(passedClaim.status, equals('passed_to_finder'));

      // 4. Log in as finder (Terry Melton - poster of item_f3_laptop)
      await repo.login(email: 'terry@campus.edu', password: 'password123');

      // Finder inspects claims before approving
      final finderClaimsBefore = await repo.getClaimsForItem('item_f3_laptop');
      expect(finderClaimsBefore.any((c) => c.id == submittedClaim.id), isTrue);

      // Finder approves claim
      final finderApprovalResult = await repo.approveClaim(submittedClaim.id);

      // Verify finder's return value never receives the handover OTP
      expect(finderApprovalResult.handoverOtp, isNull);

      // Verify finder's claims list never contains the handover OTP
      final finderClaimsAfter = await repo.getClaimsForItem('item_f3_laptop');
      final finderClaimView = finderClaimsAfter.firstWhere((c) => c.id == submittedClaim.id);
      expect(finderClaimView.handoverOtp, isNull);

      // 5. Log back in as claimant (Alex Chen) and verify getMyClaims() has the 6-digit code
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final myClaims = await repo.getMyClaims();
      final claimantClaimView = myClaims.firstWhere((c) => c.id == submittedClaim.id);

      expect(claimantClaimView.status, equals('handover_pending'));
      expect(claimantClaimView.handoverOtp, isNotNull);
      expect(claimantClaimView.handoverOtp!.length, equals(6));
      expect(int.tryParse(claimantClaimView.handoverOtp!), isNotNull);

      // 6. Finder confirms handover with correct OTP
      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final resolvedClaim = await repo.confirmHandover(submittedClaim.id, claimantClaimView.handoverOtp!);
      expect(resolvedClaim.status, equals('resolved'));
    });

    test('Low-value item claim approval does not generate a handover code', () async {
      // 1. Log in as claimant (Alex Chen)
      await repo.login(email: 'alex@campus.edu', password: 'password123');

      // 2. Submit claim on a low-value item (item_f7_keys - keys category)
      final submittedClaim = await repo.submitClaim(
        itemId: 'item_f7_keys',
        answers: ['Set of keys with Subaru fob', 'Dorm room 102 tag'],
      );

      expect(submittedClaim.isHighValue, isFalse);

      // 3. Admin passes
      await repo.login(email: 'admin@campus.edu', password: 'password123');
      await repo.passClaim(submittedClaim.id);

      // 4. Finder approves
      await repo.login(email: 'terry@campus.edu', password: 'password123');
      final approvedClaim = await repo.approveClaim(submittedClaim.id);
      expect(approvedClaim.status, equals('approved'));
      expect(approvedClaim.handoverOtp, isNull);

      // 5. Claimant gets no code
      await repo.login(email: 'alex@campus.edu', password: 'password123');
      final myClaims = await repo.getMyClaims();
      final claimantClaim = myClaims.firstWhere((c) => c.id == submittedClaim.id);
      expect(claimantClaim.status, equals('approved'));
      expect(claimantClaim.handoverOtp, isNull);
    });
  });
}
