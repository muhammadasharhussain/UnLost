// lib/core/widgets/accent_pill.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Paints a halftone dot gradient (dots shrink towards the lower right),
/// used on lemon surfaces.
class HalftonePainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double maxRadius;

  const HalftonePainter({
    required this.color,
    this.spacing = 6,
    this.maxRadius = 1.9,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        // Offset every other row for a classic halftone lattice.
        final dx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final dy = row * spacing;
        final t = ((dx / size.width) * 0.65 + (dy / size.height) * 0.35)
            .clamp(0.0, 1.0);
        final r = maxRadius * (1 - t);
        if (r > 0.25) canvas.drawCircle(Offset(dx, dy), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HalftonePainter old) =>
      old.color != color || old.spacing != spacing || old.maxRadius != maxRadius;
}

/// Lemon pill with a halftone texture: the app's primary call to action.
class AccentPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final double? width;

  const AccentPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 56,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HalftonePainter(
                    color: AppColors.onAccent.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: AppColors.onAccent),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.onAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
