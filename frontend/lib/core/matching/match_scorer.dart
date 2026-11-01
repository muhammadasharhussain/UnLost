// lib/core/matching/match_scorer.dart

/// Match strength band used consistently across the entire app.
enum MatchBand {
  strong,
  partial,
  weak;

  static MatchBand fromScore(int score) {
    if (score >= 75) return MatchBand.strong;
    if (score >= 40) return MatchBand.partial;
    return MatchBand.weak;
  }

  String get label {
    switch (this) {
      case MatchBand.strong:
        return 'Strong';
      case MatchBand.partial:
        return 'Partial';
      case MatchBand.weak:
        return 'Weak';
    }
  }
}

/// Generic tokens that carry almost no weight in matching.
const List<String> kGenericTokens = [
  // Colours
  'black', 'blue', 'red', 'green', 'yellow', 'white', 'grey', 'gray',
  'brown', 'silver', 'gold', 'purple', 'orange', 'pink', 'dark', 'light',
  // Common descriptors
  'small', 'big', 'large', 'medium', 'tiny', 'old', 'new', 'used',
  'brand', 'card', 'item', 'thing', 'one', 'side', 'back', 'front',
  'top', 'bottom', 'left', 'right', 'color', 'colour', 'case', 'cover',
  'strap', 'pouch', 'sleeve', 'cable', 'cord', 'box', 'bag',
  // Category words
  'wallet', 'phone', 'laptop', 'electronics', 'documents', 'keys',
  'jewellery', 'jewelry', 'clothing', 'other', 'badge', 'id', 'student',
  'device', 'watch', 'charger', 'book', 'bottle', 'headphones',
];

/// Common English stop words.
const Set<String> _kStopWords = {
  'a', 'an', 'the', 'in', 'on', 'at', 'by', 'for', 'with', 'about', 'against',
  'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below',
  'to', 'from', 'up', 'down', 'of', 'off', 'over', 'under', 'again', 'further',
  'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any',
  'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor',
  'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can',
  'will', 'just', 'don', 'should', 'now', 'i', 'me', 'my', 'myself', 'we',
  'our', 'ours', 'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves',
  'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its',
  'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which',
  'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was',
  'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does',
  'did', 'doing', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while',
  'got', 'also', 'inside', 'contains',
};

const Map<String, String> _kNumberWords = {
  'zero': '0',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
  'ten': '10',
  'eleven': '11',
  'twelve': '12',
  'thirteen': '13',
  'fourteen': '14',
  'fifteen': '15',
  'sixteen': '16',
  'seventeen': '17',
  'eighteen': '18',
  'nineteen': '19',
  'twenty': '20',
  'thirty': '30',
  'forty': '40',
  'fifty': '50',
  'sixty': '60',
  'seventy': '70',
  'eighty': '80',
  'ninety': '90',
  'hundred': '100',
};

class QuestionMatchResult {
  final int score; // 0 - 100
  final List<String> matchedTokens;
  final List<String> missingTokens;
  final bool hasUniqueTokens;

  const QuestionMatchResult({
    required this.score,
    required this.matchedTokens,
    required this.missingTokens,
    required this.hasUniqueTokens,
  });
}

class MatchResult {
  final int score; // 0 - 100
  final MatchBand band;
  final List<QuestionMatchResult> perQuestion;
  final bool isLowConfidence;

  const MatchResult({
    required this.score,
    required this.band,
    required this.perQuestion,
    required this.isLowConfidence,
  });
}

class MatchScorer {
  /// Normalises text: lowercase, punctuation removed, number words to digits,
  /// stop-words stripped.
  static List<String> tokenizeAndNormalize(String text) {
    if (text.trim().isEmpty) return [];

    // Replace currency signs, hashes, hyphens with spaces or clean them
    var cleaned = text.toLowerCase();

    // Split words and separate alphanumeric boundaries (e.g. 130w -> 130 w)
    final separated = cleaned.replaceAllMapped(
      RegExp(r'(\d+)([a-zA-Z]+)|([a-zA-Z]+)(\d+)'),
      (m) => '${m[1] ?? m[3]} ${m[2] ?? m[4]}',
    );

    final rawTokens = separated
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final List<String> result = [];
    for (var token in rawTokens) {
      final mappedNum = _kNumberWords[token];
      final val = mappedNum ?? token;
      if (!_kStopWords.contains(val) && val.length > 1) {
        result.add(val);
      } else if (RegExp(r'^\d+$').hasMatch(val)) {
        // Keep single digit numbers
        result.add(val);
      }
    }
    return result;
  }

  /// Levenshtein distance between two strings
  static int levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[s2.length];
  }

  /// Check if a token is a number
  static bool isNumeric(String token) => RegExp(r'^\d+$').hasMatch(token);

  /// Check if a token is generic
  static bool isGeneric(String token, String category) {
    return kGenericTokens.contains(token) || token == category.toLowerCase();
  }

  /// Score a single question pair.
  static QuestionMatchResult scoreQuestion({
    required String finderAnswer,
    required String claimantAnswer,
    required String category,
  }) {
    final claimantRaw = claimantAnswer.trim().toLowerCase();
    // Rule 6: Empty answers, one-word filler, or "don't know" / "no idea" / "not sure" score 0.
    final fillerPhrases = [
      'no idea', 'don\'t know', 'dont know', 'not sure', 'asdf', 'unknown',
      'idk', 'dunno', 'n/a', 'none', 'nothing', 'can\'t remember', 'cant remember'
    ];
    if (claimantRaw.isEmpty ||
        fillerPhrases.contains(claimantRaw) ||
        (claimantRaw.split(RegExp(r'\s+')).length == 1 &&
            ['yes', 'no', 'maybe', 'idk', 'item', 'found', 'lost'].contains(claimantRaw))) {
      final fTokens = tokenizeAndNormalize(finderAnswer);
      final hasUnique = fTokens.any((t) => !isGeneric(t, category));
      return QuestionMatchResult(
        score: 0,
        matchedTokens: [],
        missingTokens: fTokens,
        hasUniqueTokens: hasUnique,
      );
    }

    final finderTokens = tokenizeAndNormalize(finderAnswer);
    final claimantTokens = tokenizeAndNormalize(claimantAnswer);

    if (finderTokens.isEmpty) {
      return const QuestionMatchResult(
        score: 50,
        matchedTokens: [],
        missingTokens: [],
        hasUniqueTokens: false,
      );
    }

    final finderNumbers = finderTokens.where(isNumeric).toSet();
    final claimantNumbers = claimantTokens.where(isNumeric).toSet();

    // Rule 5: Numbers must match exactly. A wrong number is a hard miss for that token and subtracts penalty.
    int numberPenalty = 0;
    if (finderNumbers.isNotEmpty) {
      if (claimantNumbers.isNotEmpty) {
        // Claimant provided numbers
        final commonNumbers = finderNumbers.intersection(claimantNumbers);
        final mismatchedNumbers = claimantNumbers.difference(finderNumbers);
        if (mismatchedNumbers.isNotEmpty && commonNumbers.isEmpty) {
          numberPenalty += 35 * mismatchedNumbers.length;
        }
      } else {
        // Finder specified numbers, claimant omitted them
        numberPenalty += 15;
      }
    }

    final matched = <String>[];
    final missing = <String>[];
    double totalWeight = 0.0;
    double matchedWeight = 0.0;

    bool hasUnique = false;

    for (final fToken in finderTokens) {
      final isNum = isNumeric(fToken);
      final isGen = isGeneric(fToken, category);
      if (!isGen) hasUnique = true;

      // Weighting: numerics highest, unique text mid, generic low.
      // Short tokens (<=3 chars) that aren't numbers also get lower weight.
      final double weight = isNum ? 3.0 : (isGen ? 0.3 : (fToken.length <= 3 ? 0.8 : 2.0));
      totalWeight += weight;

      // Check match against claimant tokens
      bool tokenMatched = false;
      for (final cToken in claimantTokens) {
        if (isNum) {
          if (cToken == fToken) {
            tokenMatched = true;
            break;
          }
        } else {
          // Rule 4: Levenshtein distance 1 (2 for tokens of 8+ characters)
          if (fToken == cToken) {
            tokenMatched = true;
            break;
          }
          final maxDist = fToken.length >= 8 ? 2 : 1;
          if (levenshtein(fToken, cToken) <= maxDist) {
            tokenMatched = true;
            break;
          }
          // Substring match for long tokens (e.g. "usbc" inside "usbccharger")
          if (fToken.length >= 5 && cToken.length >= 5) {
            if (cToken.contains(fToken) || fToken.contains(cToken)) {
              tokenMatched = true;
              break;
            }
          }
        }
      }

      if (tokenMatched) {
        matchedWeight += weight;
        matched.add(fToken);
      } else {
        missing.add(fToken);
      }
    }

    if (totalWeight == 0) totalWeight = 1.0;
    double rawScore = (matchedWeight / totalWeight) * 100.0;
    rawScore -= numberPenalty;

    int qScore = rawScore.round().clamp(0, 100);

    return QuestionMatchResult(
      score: qScore,
      matchedTokens: matched,
      missingTokens: missing,
      hasUniqueTokens: hasUnique,
    );
  }

  /// Evaluates full match between finder's hidden fields and claimant's answers.
  // TODO semantic match via GroqService
  static MatchResult score({
    required List<String> finderAnswers,
    required List<String> claimantAnswers,
    required String category,
  }) {
    if (finderAnswers.isEmpty) {
      return const MatchResult(
        score: 0,
        band: MatchBand.weak,
        perQuestion: [],
        isLowConfidence: true,
      );
    }

    final List<QuestionMatchResult> perQ = [];
    int sumScores = 0;
    bool hasAnyUniqueTokens = false;
    bool anyQuestionZero = false;
    bool hasOnlyGenericClaimant = true;

    for (int i = 0; i < finderAnswers.length; i++) {
      final fAns = finderAnswers[i];
      final cAns = i < claimantAnswers.length ? claimantAnswers[i] : '';

      final cTokens = tokenizeAndNormalize(cAns);
      if (cTokens.any((t) => !isGeneric(t, category))) {
        hasOnlyGenericClaimant = false;
      }

      final qResult = scoreQuestion(
        finderAnswer: fAns,
        claimantAnswer: cAns,
        category: category,
      );

      if (qResult.hasUniqueTokens) {
        hasAnyUniqueTokens = true;
      }
      if (qResult.score == 0) {
        anyQuestionZero = true;
      }

      sumScores += qResult.score;
      perQ.add(qResult);
    }

    double avgScore = sumScores / finderAnswers.length;
    int finalScore = avgScore.round();

    // Rule 7: If a claimant answered only with generic words, cap at 35.
    if (hasOnlyGenericClaimant && claimantAnswers.any((a) => a.trim().isNotEmpty)) {
      if (finalScore > 35) finalScore = 35;
    }

    // Rule 7: If any question scored 0 and the other is below 60, cap at 45.
    if (anyQuestionZero && (finderAnswers.length > 1)) {
      final otherScores = perQ.where((q) => q.score > 0).map((q) => q.score).toList();
      if (otherScores.isEmpty || otherScores.any((s) => s < 60)) {
        if (finalScore > 45) finalScore = 45;
      }
    }

    finalScore = finalScore.clamp(0, 100);

    // Rule 8: If finder's answers contain no unique tokens, isLowConfidence = true
    final isLowConfidence = !hasAnyUniqueTokens;

    return MatchResult(
      score: finalScore,
      band: MatchBand.fromScore(finalScore),
      perQuestion: perQ,
      isLowConfidence: isLowConfidence,
    );
  }
}
