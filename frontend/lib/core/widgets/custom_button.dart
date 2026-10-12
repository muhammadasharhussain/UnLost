// lib/core/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'beam_search_bar.dart';
import 'glow_pill_button.dart';

/// glow = soft violet glowing pill, glowGlass = same shape in glass.
enum ButtonVariant { primary, secondary, outline, danger, glow, glowGlass }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.accent;
        fg = AppColors.onAccent;
        break;
      case ButtonVariant.secondary:
        bg = p.isDark ? AppColors.darkCardSubtle : AppColors.lightCard;
        fg = p.text;
        borderSide = BorderSide(color: p.hairline);
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = p.text;
        borderSide = BorderSide(
          color: p.isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        );
        break;
      case ButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case ButtonVariant.glow:
      case ButtonVariant.glowGlass:
        bg = Colors.transparent;
        fg = p.text;
        break;
    }

    if (variant == ButtonVariant.glow || variant == ButtonVariant.glowGlass) {
      return GlowPillButton(
        label: text,
        icon: icon,
        width: width ?? double.infinity,
        height: height,
        isLoading: isLoading,
        tone: variant == ButtonVariant.glow ? GlowTone.violet : GlowTone.glass,
        onPressed: onPressed,
      );
    }

    // Secondary and outline buttons use the dark beam pill (beam runs on
    // hover, focus and press). Primary stays lemon, danger stays red.
    if (variant == ButtonVariant.secondary || variant == ButtonVariant.outline) {
      return BeamSurface(
        width: width ?? double.infinity,
        height: height,
        semanticLabel: text,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          side: borderSide,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
