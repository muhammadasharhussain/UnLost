// lib/core/widgets/circle_icon_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Round, softly outlined icon button (back, theme toggle, etc.).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool filled; // true = lemon fill

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 48,
    this.iconSize = 20,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.accent : p.circleFill,
        border: filled ? null : Border.all(color: p.hairline),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: filled ? AppColors.onAccent : p.text,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      child: tooltip == null ? button : Tooltip(message: tooltip!, child: button),
    );
  }
}
