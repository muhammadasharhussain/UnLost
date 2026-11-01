// lib/core/widgets/trust_strip.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Replacement for the clock-style tick-ring dial: a row of 20 thin vertical
/// notches, lit up to the score (neon rose for lit, border/tickIdle for unlit),
/// with the score numeral beside it in mono font.
class TrustStrip extends StatelessWidget {
  final int score;
  final bool showNumber;
  final double height;

  const TrustStrip({
    super.key,
    required this.score,
    this.showNumber = true,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final litColor = dark ? AppColors.rose : AppColors.roseInk;
    final unlitColor = dark ? AppColors.darkBorder : AppColors.lightBorder;

    final clamped = score.clamp(0, 100);
    // 20 notches total -> each notch is 5 points
    final litNotches = (clamped / 5).round();

    return Semantics(
      label: 'Trust score $clamped out of 100',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(20, (index) {
              final isLit = index < litNotches;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3.0,
                height: height,
                decoration: BoxDecoration(
                  color: isLit ? litColor : unlitColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
          if (showNumber) ...[
            const SizedBox(width: 10),
            Text(
              '$clamped',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: height * 0.85,
                fontWeight: FontWeight.w700,
                color: context.palette.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
