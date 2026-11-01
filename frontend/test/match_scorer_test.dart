// test/match_scorer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/matching/match_scorer.dart';

void main() {
  group('MatchScorer Unit Tests', () {
    test('identical answers: score >= 90', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Dell XPS 15 with GitHub and Python stickers on the lid',
          'Came in a black felt zip sleeve with USB-C 130W charger',
        ],
        claimantAnswers: [
          'Dell XPS 15 with GitHub and Python stickers on the lid',
          'Came in a black felt zip sleeve with USB-C 130W charger',
        ],
        category: 'electronics',
      );
      expect(result.score, greaterThanOrEqualTo(90));
      expect(result.band, equals(MatchBand.strong));
    });

    test('same meaning, reworded, with unique details kept: 60 to 89', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Dell XPS 15 with GitHub and Python stickers on the lid',
          'Came in a black felt zip sleeve with USB-C 130W charger',
        ],
        claimantAnswers: [
          'It is a Dell XPS laptop with some coding stickers (GitHub octocat and Python)',
          'I left it in a felt sleeve bag along with the 130W Dell USB-C brick',
        ],
        category: 'electronics',
      );
      expect(result.score, inInclusiveRange(60, 89));
      expect(result.band, isIn([MatchBand.partial, MatchBand.strong]));
    });

    test('completely unrelated answers: < 25', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Computer Science Department student card ending in #4092',
          'Attached to a navy blue campus lanyard',
        ],
        claimantAnswers: [
          'Architecture faculty card with red lanyard',
          'Gold keychain with metal whistle',
        ],
        category: 'documents',
      );
      expect(result.score, lessThan(25));
      expect(result.band, equals(MatchBand.weak));
    });

    test('only generic words match ("black wallet" against "black phone"): < 40', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Black leather wallet with credit cards',
        ],
        claimantAnswers: [
          'Black phone case',
        ],
        category: 'wallet',
      );
      expect(result.score, lessThan(40));
      expect(result.band, equals(MatchBand.weak));
    });

    test('wrong number ("ending 1234" against "ending 4092"): < 40', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Card ending 4092 with blue strap',
        ],
        claimantAnswers: [
          'Card ending 1234 with blue strap',
        ],
        category: 'documents',
      );
      expect(result.score, lessThan(40));
      expect(result.band, equals(MatchBand.weak));
    });

    test('empty and "no idea": 0', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'MacBook Pro with Apple sticker on lid',
          'Serial number ending in 8892',
        ],
        claimantAnswers: [
          '',
          'no idea',
        ],
        category: 'electronics',
      );
      expect(result.score, equals(0));
      expect(result.band, equals(MatchBand.weak));
    });

    test('one typo in a brand name ("Samsng" against "Samsung"): still matches', () {
      final result = MatchScorer.score(
        finderAnswers: [
          'Samsung Galaxy S23 Ultra in violet case',
        ],
        claimantAnswers: [
          'Samsng Galaxy S23 Ultra phone in violet case',
        ],
        category: 'phone',
      );
      expect(result.score, greaterThanOrEqualTo(75));
      expect(result.perQuestion.first.matchedTokens, contains('samsung'));
    });

    test('band boundaries: 74 is Partial, 75 is Strong, 39 is Weak, 40 is Partial', () {
      expect(MatchBand.fromScore(75), equals(MatchBand.strong));
      expect(MatchBand.fromScore(74), equals(MatchBand.partial));
      expect(MatchBand.fromScore(40), equals(MatchBand.partial));
      expect(MatchBand.fromScore(39), equals(MatchBand.weak));
    });
  });
}
