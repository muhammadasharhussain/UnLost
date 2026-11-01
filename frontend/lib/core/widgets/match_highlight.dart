// lib/core/widgets/match_highlight.dart
// Shows "stored finder answer vs claimant answer" with matched words in
// cerulean and missing words in neon rose. Used by the finder's claim review
// and by the admin queue so both read the same way.
import 'package:flutter/material.dart';
import '../matching/match_scorer.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum _WordState { plain, matched, missing }

/// Does [token] fuzzy-match any of [pool]? Same rules as the scorer:
/// numbers must be exact, words allow 1 typo (2 for 8+ characters).
bool _fuzzyIn(String token, Iterable<String> pool) {
  final isNum = MatchScorer.isNumeric(token);
  for (final m in pool) {
    if (m == token) return true;
    if (isNum || MatchScorer.isNumeric(m)) continue;
    final maxDist = m.length >= 8 ? 2 : 1;
    if (MatchScorer.levenshtein(m, token) <= maxDist) return true;
    if (m.length >= 5 && token.length >= 5 && (m.contains(token) || token.contains(m))) {
      return true;
    }
  }
  return false;
}

/// One answer, with its words coloured.
///
/// [isFinderSide] = true: words are coloured matched (cerulean) or missing
/// (rose) using the scorer's token lists. false (claimant side): only words
/// that matched something in the finder's answer are coloured.
class HighlightedAnswer extends StatelessWidget {
  final String text;
  final List<String> matchedTokens;
  final List<String> missingTokens;
  final bool isFinderSide;
  final double fontSize;

  const HighlightedAnswer({
    super.key,
    required this.text,
    required this.matchedTokens,
    required this.missingTokens,
    required this.isFinderSide,
    this.fontSize = 13.5,
  });

  _WordState _stateFor(String chunk) {
    final tokens = MatchScorer.tokenizeAndNormalize(chunk);
    if (tokens.isEmpty) return _WordState.plain;

    if (isFinderSide) {
      if (tokens.any(matchedTokens.contains)) return _WordState.matched;
      if (tokens.any(missingTokens.contains)) return _WordState.missing;
      return _WordState.plain;
    }
    if (tokens.any((t) => _fuzzyIn(t, matchedTokens))) return _WordState.matched;
    return _WordState.plain;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cerulean = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;
    final rose = p.isDark ? AppColors.rose : AppColors.roseInk;

    if (text.trim().isEmpty) {
      return Text(
        'No answer',
        style: TextStyle(fontSize: fontSize, fontStyle: FontStyle.italic, color: p.textFaint),
      );
    }

    final base = TextStyle(fontSize: fontSize, height: 1.45, color: p.text);
    final spans = <InlineSpan>[];
    final re = RegExp(r'[A-Za-z0-9]+|[^A-Za-z0-9]+');

    for (final m in re.allMatches(text)) {
      final chunk = m.group(0)!;
      if (!RegExp(r'[A-Za-z0-9]').hasMatch(chunk)) {
        spans.add(TextSpan(text: chunk, style: base));
        continue;
      }
      switch (_stateFor(chunk)) {
        case _WordState.matched:
          spans.add(TextSpan(
            text: chunk,
            style: base.copyWith(
              color: cerulean,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: cerulean,
            ),
          ));
          break;
        case _WordState.missing:
          spans.add(TextSpan(
            text: chunk,
            style: base.copyWith(
              color: rose,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
              decorationColor: rose,
            ),
          ));
          break;
        case _WordState.plain:
          spans.add(TextSpan(text: chunk, style: base));
          break;
      }
    }

    return Text.rich(TextSpan(children: spans));
  }
}

/// Legend: "Matched" in cerulean, "Missing" in neon rose.
class MatchLegend extends StatelessWidget {
  const MatchLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cerulean = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;
    final rose = p.isDark ? AppColors.rose : AppColors.roseInk;

    Widget chip(String label, Color color, TextDecorationStyle style) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 3, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        chip('MATCHED', cerulean, TextDecorationStyle.solid),
        chip('MISSING', rose, TextDecorationStyle.dashed),
      ],
    );
  }
}

/// Full per-question comparison block.
class MatchComparisonBlock extends StatelessWidget {
  final List<String> finderAnswers;
  final List<String> claimantAnswers;
  final String category;

  /// Wording for the stored side, e.g. "Stored finder answer".
  final String finderLabel;
  final String claimantLabel;

  const MatchComparisonBlock({
    super.key,
    required this.finderAnswers,
    required this.claimantAnswers,
    required this.category,
    this.finderLabel = 'Stored finder answer',
    this.claimantLabel = 'Claimant answer',
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = claimantAnswers.length > finderAnswers.length
        ? claimantAnswers.length
        : finderAnswers.length;

    TextStyle label() => TextStyle(
          fontFamily: AppTheme.monoFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: p.textFaint,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MatchLegend(),
        const SizedBox(height: 10),
        for (var i = 0; i < count; i++) ...[
          Builder(builder: (context) {
            final fAns = i < finderAnswers.length ? finderAnswers[i] : '';
            final cAns = i < claimantAnswers.length ? claimantAnswers[i] : '';
            final q = MatchScorer.scoreQuestion(
              finderAnswer: fAns,
              claimantAnswer: cAns,
              category: category,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUESTION ${i + 1}', style: label()),
                  const SizedBox(height: 6),
                  Text(finderLabel, style: TextStyle(fontSize: 11.5, color: p.textDim)),
                  const SizedBox(height: 2),
                  HighlightedAnswer(
                    text: fAns,
                    matchedTokens: q.matchedTokens,
                    missingTokens: q.missingTokens,
                    isFinderSide: true,
                  ),
                  const SizedBox(height: 8),
                  Text(claimantLabel, style: TextStyle(fontSize: 11.5, color: p.textDim)),
                  const SizedBox(height: 2),
                  HighlightedAnswer(
                    text: cAns,
                    matchedTokens: q.matchedTokens,
                    missingTokens: q.missingTokens,
                    isFinderSide: false,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
