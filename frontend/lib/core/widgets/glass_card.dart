// lib/core/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
enum CardTone { neutral, cerulean, indigo, accent }

class GlassCard extends StatelessWidget {
  final Widget child;
  final CardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.tone = CardTone.neutral,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.onTap,
  });

  static Color foreground(BuildContext context, CardTone tone) {
    switch (tone) {
      case CardTone.neutral:
        return context.palette.text;
      case CardTone.accent:
        return AppColors.onAccent;
      case CardTone.cerulean:
      case CardTone.indigo:
        return AppColors.darkTextPrimary;
    }
  }

  static Color foregroundDim(BuildContext context, CardTone tone) {
    switch (tone) {
      case CardTone.neutral:
        return context.palette.textDim;
      case CardTone.accent:
        return AppColors.onAccent.withValues(alpha: 0.65);
      case CardTone.cerulean:
      case CardTone.indigo:
        return AppColors.darkTextPrimary.withValues(alpha: 0.72);
    }
  }

  BoxDecoration _decoration(UnlostPalette p) {
    final r = BorderRadius.circular(radius);
    switch (tone) {
      case CardTone.neutral:
        return BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.cardTop, p.cardBottom],
          ),
          border: Border.all(color: p.hairline),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 28, offset: const Offset(0, 12)),
          ],
        );
      case CardTone.cerulean:
        return BoxDecoration(
          borderRadius: r,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emeraldGradA, AppColors.champagneGradB],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.champagneGradB.withValues(alpha: p.isDark ? 0.25 : 0.20),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        );
      case CardTone.indigo:
        return BoxDecoration(
          borderRadius: r,
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.95,
            colors: [AppColors.indigoCore, AppColors.indigoMid, AppColors.indigoGlow],
            stops: [0.0, 0.62, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigoMid.withValues(alpha: p.isDark ? 0.35 : 0.30),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        );
      case CardTone.accent:
        return BoxDecoration(
          borderRadius: r,
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = foreground(context, tone);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: _decoration(p),
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: content,
          ),
        ),
      ),
    );
  }
}