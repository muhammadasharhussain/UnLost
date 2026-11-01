// test/review_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/review_logic.dart';
import 'package:student_app/data/models/claim_model.dart';
import 'package:student_app/data/models/item_model.dart';
import 'package:student_app/data/models/review_model.dart';

ItemModel _item({
  String id = 'item_1',
  String type = 'found',
  String status = 'resolved',
  String posterId = 'finder',
  String posterName = 'Fiona Finder',
}) =>
    ItemModel(
      id: id,
      type: type,
      title: 'Black wallet',
      category: 'wallet',
      description: 'desc',
      area: 'Library',
      dateTime: DateTime(2026, 10, 1),
      status: status,
      posterId: posterId,
      posterName: posterName,
      posterTrustScore: 70,
      createdAt: DateTime(2026, 10, 1),
    );

ClaimModel _claim({
  String id = 'c1',
  String status = 'resolved',
  String claimantId = 'owner',
  String claimantName = 'Omar Owner',
}) =>
    ClaimModel(
      id: id,
      itemId: 'item_1',
      itemTitle: 'Black wallet',
      itemCategory: 'wallet',
      claimantId: claimantId,
      claimantName: claimantName,
      claimantTrustScore: 60,
      answers: const ['a'],
      status: status,
      createdAt: DateTime(2026, 10, 2),
    );

void main() {
  group('reviewTargetFor', () {
    test('finder reviews the claimant', () {
      final t = reviewTargetFor(item: _item(), claim: _claim(), viewerId: 'finder');
      expect(t, isNotNull);
      expect(t!.aboutUserId, 'owner');
      expect(t.aboutName, 'Omar Owner');
      expect(t.caseId, 'item_1');
    });

    test('claimant reviews the finder', () {
      final t = reviewTargetFor(item: _item(), claim: _claim(), viewerId: 'owner');
      expect(t!.aboutUserId, 'finder');
      expect(t.aboutName, 'Fiona Finder');
    });

    test('lost post: owner (poster) reviews the finder who claimed', () {
      final item = _item(type: 'lost', posterId: 'owner', posterName: 'Omar Owner');
      final claim = _claim(claimantId: 'finder', claimantName: 'Fiona Finder', status: 'approved');
      final t = reviewTargetFor(item: item, claim: claim, viewerId: 'owner');
      expect(t!.aboutUserId, 'finder');
    });

    test('nobody else, and nothing until the case is resolved', () {
      expect(reviewTargetFor(item: _item(), claim: _claim(), viewerId: 'stranger'), isNull);
      expect(reviewTargetFor(item: _item(), claim: _claim(), viewerId: ''), isNull);
      expect(
        reviewTargetFor(item: _item(status: 'active'), claim: _claim(), viewerId: 'finder'),
        isNull,
      );
    });

    test('you cannot review yourself', () {
      final claim = _claim(claimantId: 'finder');
      expect(reviewTargetFor(item: _item(), claim: claim, viewerId: 'finder'), isNull);
    });
  });

  group('winningClaim', () {
    test('prefers resolved, then approved, ignores others', () {
      final list = [
        _claim(id: 'a', status: 'rejected'),
        _claim(id: 'b', status: 'approved'),
        _claim(id: 'c', status: 'resolved'),
      ];
      expect(winningClaim(list)!.id, 'c');
      expect(winningClaim([list[0], list[1]])!.id, 'b');
      expect(winningClaim([list[0]]), isNull);
      expect(winningClaim(const []), isNull);
    });
  });

  group('flagging', () {
    test('1 or 2 stars with a comment is flagged', () {
      expect(isFlaggedRating(1, 'rude'), isTrue);
      expect(isFlaggedRating(2, 'late'), isTrue);
      expect(isFlaggedRating(2, '   '), isFalse);
      expect(isFlaggedRating(3, 'meh'), isFalse);
    });

    test('ReviewModel agrees with the helper', () {
      final r = ReviewModel(
        id: 'r',
        caseId: 'c',
        authorId: 'a',
        authorName: 'Terry Melton',
        aboutUserId: 'b',
        rating: 1,
        outcome: 'Did not get it',
        comment: 'No show',
        createdAt: DateTime(2026, 10, 3),
      );
      expect(r.isFlaggedForAdmin, isTrue);
    });
  });

  group('ReviewModel.publicName', () {
    ReviewModel withName(String n) => ReviewModel(
          id: 'r',
          caseId: 'c',
          authorId: 'a',
          authorName: n,
          aboutUserId: 'b',
          rating: 5,
          outcome: 'Got my item back',
          createdAt: DateTime(2026, 10, 3),
        );

    test('first name plus last initial', () {
      expect(withName('Terry Melton').publicName, 'Terry M.');
      expect(withName('Terry M.').publicName, 'Terry M.');
      expect(withName('Saad').publicName, 'Saad');
      expect(withName('  ').publicName, 'Student');
    });
  });
}
