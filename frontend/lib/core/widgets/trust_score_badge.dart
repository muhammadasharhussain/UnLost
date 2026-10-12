// lib/core/widgets/trust_score_badge.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TrustScoreBadge extends StatelessWidget {
  final int score;
  final bool showProgress;
  final bool isCompact;

  const TrustScoreBadge({
    super.key,
    required this.score,
    this.showProgress = false,
    this.isCompact = false,
  });

  String get label {
    if (score >= 80) return 'Trusted';
    if (score >= 50) return 'Building trust';
    return 'New account';
  }

  Color get baseColor {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.info;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.readable(baseColor, Theme.of(context).brightness);
    if (!showProgress) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 9,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              score >= 80
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.shield_fill,
              size: isCompact ? 11 : 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$label ($score)',
              style: TextStyle(
                color: color,
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  score >= 80
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.shield_fill,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              '$score / 100',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
