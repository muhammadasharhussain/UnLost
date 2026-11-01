// test/case_recommender_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/matching/case_recommender.dart';
import 'package:student_app/data/models/item_model.dart';

void main() {
  group('CaseRecommender Unit Tests', () {
    final now = DateTime.now();

    final lostLaptop = ItemModel(
      id: 'lost_laptop_1',
      type: 'lost',
      title: 'Dell laptop black',
      category: 'electronics',
      description: 'Lost my black Dell XPS 15 laptop in the library study room',
      area: 'Library',
      dateTime: now,
      status: 'active',
      posterId: 'user_a',
      posterName: 'User A',
      posterTrustScore: 70,
      createdAt: now,
    );

    final foundXps = ItemModel(
      id: 'found_xps_1',
      type: 'found',
      title: 'black Dell XPS laptop',
      category: 'electronics',
      description: 'Found a silver and black Dell XPS plugged into the desk',
      area: 'Library',
      dateTime: now.subtract(const Duration(hours: 4)),
      status: 'active',
      posterId: 'user_b',
      posterName: 'User B',
      posterTrustScore: 80,
      createdAt: now,
    );

    final foundWallet = ItemModel(
      id: 'found_wallet_1',
      type: 'found',
      title: 'black wallet',
      category: 'wallet',
      description: 'Found black leather wallet with cash',
      area: 'Cafeteria',
      dateTime: now,
      status: 'active',
      posterId: 'user_c',
      posterName: 'User C',
      posterTrustScore: 60,
      createdAt: now,
    );

    final pendingFoundLaptop = ItemModel(
      id: 'found_laptop_pending',
      type: 'found',
      title: 'Dell laptop',
      category: 'electronics',
      description: 'Found Dell computer',
      area: 'Library',
      dateTime: now,
      status: 'pending_review',
      posterId: 'user_d',
      posterName: 'User D',
      posterTrustScore: 50,
      createdAt: now,
    );

    test('lost Dell laptop matches found Dell XPS laptop', () {
      final recs = CaseRecommender.recommend(lostLaptop, [
        foundXps,
        foundWallet,
        pendingFoundLaptop,
      ]);

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.item.id, equals('found_xps_1'));
      expect(recs.first.band, equals(RecommendationBand.strong));
    });

    test('does not match found item of different category without overlap', () {
      final recs = CaseRecommender.recommend(lostLaptop, [foundWallet]);
      expect(recs, isEmpty);
    });

    test('does not match pending or rejected posts', () {
      final recs = CaseRecommender.recommend(lostLaptop, [pendingFoundLaptop]);
      expect(recs, isEmpty);
    });

    test('does not match user own posts', () {
      final myFound = foundXps.copyWith(posterId: lostLaptop.posterId);
      final recs = CaseRecommender.recommend(lostLaptop, [myFound]);
      expect(recs, isEmpty);
    });
  });
}
