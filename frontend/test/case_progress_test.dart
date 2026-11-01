// test/case_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/case_progress_logic.dart';
import 'package:student_app/data/models/item_model.dart';
import 'package:student_app/data/models/claim_model.dart';

void main() {
  group('CaseProgress Logic Tests', () {
    final now = DateTime.now();

    final testFoundItem = ItemModel(
      id: 'item_f1',
      type: 'found',
      title: 'Keys found at library',
      category: 'keys',
      description: 'Set of silver keys',
      area: 'Library',
      dateTime: now,
      status: 'active',
      posterId: 'user_finder',
      posterName: 'Finder Person',
      posterTrustScore: 80,
      createdAt: now,
    );

    final testLostItem = ItemModel(
      id: 'item_l1',
      type: 'lost',
      title: 'Lost backpack',
      category: 'bag',
      description: 'Black backpack with books',
      area: 'Student Center',
      dateTime: now,
      status: 'active',
      posterId: 'user_lost_owner',
      posterName: 'Lost Owner',
      posterTrustScore: 85,
      createdAt: now,
    );

    test('Finder view for found post: active without claims', () {
      final p = progressFor(
        item: testFoundItem,
        claims: const [],
        viewerId: 'user_finder',
        viewerIsAdmin: false,
      );
      expect(p.steps.length, equals(6));
      expect(p.steps[0].state, equals(StepState.done));
      expect(p.steps[1].state, equals(StepState.current));
      expect(p.statusText, contains('Waiting for claims'));
    });

    test('Finder view for found post: with passed claim awaiting finder', () {
      final claim = ClaimModel(
        id: 'claim_1',
        itemId: 'item_f1',
        itemTitle: 'Keys',
        itemCategory: 'keys',
        claimantId: 'user_claimant',
        claimantName: 'Claimant Person',
        claimantTrustScore: 70,
        answers: ['silver keychain'],
        finderAnswers: ['silver keychain'],
        matchScore: 85,
        status: 'passed_to_finder',
        createdAt: now,
      );

      final p = progressFor(
        item: testFoundItem,
        claims: [claim],
        viewerId: 'user_finder',
        viewerIsAdmin: false,
      );
      expect(p.steps[3].state, equals(StepState.done));
      expect(p.steps[4].state, equals(StepState.current));
      expect(p.statusText, contains('Your turn to review'));
    });

    test('Claimant view on my claim', () {
      final claim = ClaimModel(
        id: 'claim_1',
        itemId: 'item_f1',
        itemTitle: 'Keys',
        itemCategory: 'keys',
        claimantId: 'user_claimant',
        claimantName: 'Claimant Person',
        claimantTrustScore: 70,
        answers: ['silver keychain'],
        finderAnswers: ['silver keychain'],
        matchScore: 85,
        status: 'awaiting_admin',
        isHighValue: false,
        createdAt: now,
      );

      final p = progressFor(
        item: testFoundItem,
        claims: [claim],
        claimContext: claim,
        viewerId: 'user_claimant',
        viewerIsAdmin: false,
      );
      expect(p.steps[0].state, equals(StepState.done));
      expect(p.steps[1].state, equals(StepState.current));
      expect(p.statusText, contains('Waiting for admin to review your claim'));
    });

    test('Lost post owner view: finder submit match', () {
      final finderClaim = ClaimModel(
        id: 'claim_f1',
        itemId: 'item_l1',
        itemTitle: 'Lost backpack',
        itemCategory: 'bag',
        claimantId: 'user_finder_person',
        claimantName: 'Finder Guy',
        claimantTrustScore: 75,
        answers: ['I found this bag outside cafeteria'],
        finderAnswers: [],
        matchScore: 80,
        status: 'awaiting_admin',
        createdAt: now,
      );

      final p = progressFor(
        item: testLostItem,
        claims: [finderClaim],
        viewerId: 'user_lost_owner',
        viewerIsAdmin: false,
      );
      expect(p.steps[2].state, equals(StepState.current));
      expect(p.statusText, contains('A finder submitted a match'));
    });

    test('Rejected item post reflects error state', () {
      final rejectedItem = testFoundItem.copyWith(
        status: 'rejected',
        rejectionReason: 'Duplicate listing',
      );

      final p = progressFor(
        item: rejectedItem,
        claims: const [],
        viewerId: 'user_finder',
        viewerIsAdmin: false,
      );
      expect(p.isRejected, isTrue);
      expect(p.steps.last.state, equals(StepState.rejected));
      expect(p.statusText, equals('Duplicate listing'));
    });

    test('Public view shows public stages only', () {
      final p = progressFor(
        item: testFoundItem,
        claims: const [],
        viewerId: 'user_stranger',
        viewerIsAdmin: false,
      );
      expect(p.steps.length, equals(5));
      expect(p.steps[1].label, equals('OPEN'));
      expect(p.steps[1].state, equals(StepState.current));
    });
  });
}
