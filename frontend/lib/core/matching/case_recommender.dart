// lib/core/matching/case_recommender.dart
import '../../data/models/item_model.dart';
import 'match_scorer.dart';

enum RecommendationBand { strong, possible }

class Recommendation {
  final ItemModel item;
  final RecommendationBand band;
  final List<String> reasons;
  final int score;

  const Recommendation({
    required this.item,
    required this.band,
    required this.reasons,
    required this.score,
  });
}

class CaseRecommender {
  /// Category relationship map (e.g. phone <-> electronics)
  static const Map<String, List<String>> _relatedCategories = {
    'phone': ['electronics'],
    'electronics': ['phone'],
    'wallet': ['documents'],
    'documents': ['wallet'],
  };

  /// Returns top 3 recommendations from pool for a given item.
  static List<Recommendation> recommend(ItemModel post, List<ItemModel> pool) {
    final List<Recommendation> results = [];

    // Opposite type: lost looks at found, found looks at lost
    final targetType = post.isLost ? 'found' : 'lost';

    final eligible = pool.where((candidate) {
      if (candidate.type != targetType) return false;
      if (candidate.status != 'active') return false;
      if (candidate.posterId == post.posterId) return false;

      // Category check: same category or related
      final isSameCat = candidate.category.toLowerCase() == post.category.toLowerCase();
      final related = _relatedCategories[post.category.toLowerCase()] ?? [];
      final isRelatedCat = related.contains(candidate.category.toLowerCase());

      return isSameCat || isRelatedCat;
    }).toList();

    final postText = '${post.title} ${post.description}';
    final postTokens = MatchScorer.tokenizeAndNormalize(postText);
    final postUniqueTokens = postTokens.where((t) => !MatchScorer.isGeneric(t, post.category)).toSet();

    for (final candidate in eligible) {
      final reasons = <String>[];
      int score = 0;

      final candText = '${candidate.title} ${candidate.description}';
      final candTokens = MatchScorer.tokenizeAndNormalize(candText);
      final candUniqueTokens = candTokens.where((t) => !MatchScorer.isGeneric(t, candidate.category)).toSet();

      // Check unique token overlap
      final matchedUnique = <String>[];
      for (final pToken in postUniqueTokens) {
        for (final cToken in candUniqueTokens) {
          if (pToken == cToken ||
              (pToken.length >= 5 && (pToken.contains(cToken) || cToken.contains(pToken))) ||
              MatchScorer.levenshtein(pToken, cToken) <= 1) {
            matchedUnique.add(pToken);
            score += 25;
            break;
          }
        }
      }

      if (matchedUnique.isNotEmpty) {
        reasons.add('matching details: ${matchedUnique.take(2).join(', ')}');
      }

      // Same area boost
      final areaP = post.area.toLowerCase().trim();
      final areaC = candidate.area.toLowerCase().trim();
      if (areaP == areaC || (areaP.isNotEmpty && areaC.contains(areaP)) || (areaC.isNotEmpty && areaP.contains(areaC))) {
        score += 20;
        reasons.add('same area: ${candidate.area}');
      }

      // Date within 3 days boost
      final daysDiff = post.dateTime.difference(candidate.dateTime).inDays.abs();
      if (daysDiff <= 3) {
        score += 15;
        reasons.add('reported within $daysDiff day(s)');
      }

      // If only generic words matched and no unique words matched, don't recommend
      if (matchedUnique.isEmpty && score < 35) {
        continue;
      }

      final band = score >= 50 ? RecommendationBand.strong : RecommendationBand.possible;
      results.add(
        Recommendation(
          item: candidate,
          band: band,
          reasons: reasons,
          score: score,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(3).toList();
  }
}
