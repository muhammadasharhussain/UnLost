// lib/core/widgets/unlost_wordmark.dart
//
// "Unlost" drawn in dot-matrix letters: "Un" in violet, "lost" in amber/lemon.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dot_matrix_text.dart';

class UnlostWordmark extends StatelessWidget {
  final double dotSize;
  final double gap;
  const UnlostWordmark({super.key, this.dotSize = 3.4, this.gap = 1.3});

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    // Violet for "Un"; lemon on dark, deeper amber on light (lemon vanishes on light).
    final un = dark ? AppColors.primaryLight : AppColors.primary;
    final lost = dark ? AppColors.accent : const Color(0xFFD97706);
    final pitch = dotSize + gap;
    return Semantics(
      label: 'Unlost',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DotMatrixText('Un', dotSize: dotSize, gap: gap, color: un),
            SizedBox(width: pitch), // one blank column between the words
            DotMatrixText('lost', dotSize: dotSize, gap: gap, color: lost),
          ],
        ),
      ),
    );
  }
}
