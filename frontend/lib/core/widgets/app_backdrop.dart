// lib/core/widgets/app_backdrop.dart
//
// Full-screen background for the whole app, so pages are not flat white or
// flat black: a tinted base, violet and indigo glows in opposite corners, a
// dot field that thins into particles, and a few faint stars.
// Painted once and cached. Wrap a Scaffold in it and give that Scaffold
// `backgroundColor: Colors.transparent`.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _BackdropPainter(dark),
            size: Size.infinite,
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final bool dark;
  const _BackdropPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // 1. Tinted base (light mode is a cool lavender-grey, not white).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF0F0B1D), Color(0xFF09090B)]
              : const [Color(0xFFECE8F8), Color(0xFFE4E7F0)],
        ).createShader(rect),
    );

    // 2. Corner glows.
    void glow(Alignment c, double radius, Color color) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: c,
            radius: radius,
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    glow(const Alignment(1.0, -1.05), 1.0,
        AppColors.primary.withValues(alpha: dark ? 0.30 : 0.20));
    glow(const Alignment(-1.1, 0.95), 0.9,
        const Color(0xFF4F46E5).withValues(alpha: dark ? 0.22 : 0.13));
    glow(const Alignment(0.2, 0.2), 0.8,
        const Color(0xFFEC4899).withValues(alpha: dark ? 0.05 : 0.04));

    // 3. Dot field: dense near the top-right and bottom-left corners.
    final dotColor = dark ? Colors.white : AppColors.primary;
    final base = dark ? 0.50 : 0.42;
    const gap = 9.0;
    final p = Paint();
    final tr = Offset(w, 0), bl = Offset(0, h);
    final reachTR = math.max(w, h) * 0.55;
    final reachBL = math.max(w, h) * 0.38;
    final cols = (w / gap).ceil() + 1, rows = (h / gap).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * gap + (r.isOdd ? gap / 2 : 0), y = r * gap;
        final o = Offset(x, y);
        final a = math.max(
          1 - (o - tr).distance / reachTR,
          0.6 * (1 - (o - bl).distance / reachBL),
        );
        if (a <= 0.04) continue;
        final k = math.pow(a.clamp(0.0, 1.0), 1.4).toDouble();
        final hash = (((r * 73856093) ^ (c * 19349663)) & 0xFFFF) / 65535.0;
        if (hash > k * 1.2) continue;
        p.color = dotColor.withValues(alpha: base * k);
        canvas.drawCircle(o, 0.5 + 1.1 * k, p);
      }
    }

    // 4. Sparse faint stars across the rest of the screen.
    final rnd = math.Random(7);
    final count = (w * h / 5200).round();
    for (var i = 0; i < count; i++) {
      final o = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final a = 0.05 + rnd.nextDouble() * (dark ? 0.16 : 0.12);
      p.color = (dark ? Colors.white : AppColors.primary).withValues(alpha: a);
      canvas.drawCircle(o, 0.5 + rnd.nextDouble() * 0.7, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.dark != dark;
}
