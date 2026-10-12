// lib/core/widgets/particle_field.dart
//
// Soft particle backdrop for cards: a pale violet/pink wash in the top-right
// corner (and a smaller one bottom-left) with a dot grid that thins out into
// scattered particles as it fades. Painted once and cached (no animation),
// so it costs almost nothing in long lists.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ParticleField extends StatelessWidget {
  final bool dark;
  const ParticleField({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(dark),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final bool dark;
  const _ParticlePainter(this.dark);

  static const double _gap = 7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Colour washes.
    final washA = dark ? 0.26 : 0.13;
    final washB = dark ? 0.10 : 0.07;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.0, -1.0),
          radius: 1.05,
          colors: [
            AppColors.primary.withValues(alpha: washA),
            const Color(0xFFEC4899).withValues(alpha: washA * 0.35),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-1.0, 1.0),
          radius: 0.55,
          colors: [
            AppColors.primary.withValues(alpha: washB),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Dots: brightest near the top-right corner, thinning into particles.
    final dotColor = dark ? Colors.white : AppColors.primary;
    final base = dark ? 0.55 : 0.60;
    final paint = Paint();
    final corner = Offset(w, 0);
    final reachA = math.max(w * 0.62, 120.0);
    final reachB = math.max(w * 0.28, 70.0);
    final cornerB = Offset(0, h);

    final cols = (w / _gap).ceil() + 1;
    final rows = (h / _gap).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * _gap + (r.isOdd ? _gap / 2 : 0);
        final y = r * _gap;
        final p = Offset(x, y);
        final a1 = 1 - ((p - corner).distance / reachA);
        final a2 = 0.55 * (1 - ((p - cornerB).distance / reachB));
        final a = math.max(a1, a2);
        if (a <= 0.04) continue;
        final k = math.pow(a.clamp(0.0, 1.0), 1.35).toDouble();
        // Deterministic thinning: weaker areas keep fewer dots.
        final hash = (((r * 73856093) ^ (c * 19349663)) & 0xFFFF) / 65535.0;
        if (hash > k * 1.25) continue;
        paint.color = dotColor.withValues(alpha: base * k);
        canvas.drawCircle(p, 0.5 + 1.05 * k, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.dark != dark;
}
