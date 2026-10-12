// lib/core/widgets/tick_ring_gauge.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A ring made of radial ticks. Ticks up to [value] (0..1, clockwise from the
/// top) are long and bright, fading in along the arc; the rest are short and
/// dim. A lemon marker tick sits at the current value.
class TickRingGauge extends StatelessWidget {
  final double value;
  final double size;
  final int tickCount;
  final bool showMarker;
  final Duration duration;
  final Widget? child;

  const TickRingGauge({
    super.key,
    required this.value,
    this.size = 220,
    this.tickCount = 90,
    this.showMarker = true,
    this.duration = const Duration(milliseconds: 900),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = value.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return CustomPaint(
            painter: _TickRingPainter(
              value: v,
              count: tickCount,
              idle: p.tickIdle,
              active: p.tickActive,
              showMarker: showMarker,
              scale: size / 220,
            ),
            child: child == null ? null : Center(child: child),
          );
        },
      ),
    );
  }
}

class _TickRingPainter extends CustomPainter {
  final double value;
  final int count;
  final Color idle;
  final Color active;
  final bool showMarker;
  final double scale;

  _TickRingPainter({
    required this.value,
    required this.count,
    required this.idle,
    required this.active,
    required this.showMarker,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final activeTicks = (value * count).round();

    final idlePaint = Paint()
      ..color = idle
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, 1.4 * scale);
    final activePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, 1.8 * scale);

    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / count;
      final major = i % 5 == 0;
      final isActive = i < activeTicks;

      final len = (isActive ? (major ? 17.0 : 11.0) : (major ? 9.0 : 5.5)) * scale;
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      final p1 = center + Offset(cosA, sinA) * outer;
      final p2 = center + Offset(cosA, sinA) * (outer - len);

      if (isActive) {
        final t = activeTicks <= 1 ? 1.0 : i / (activeTicks - 1);
        activePaint.color = active.withValues(alpha: 0.25 + 0.75 * t);
        canvas.drawLine(p1, p2, activePaint);
      } else {
        canvas.drawLine(p1, p2, idlePaint);
      }
    }

    if (showMarker) {
      final a = -math.pi / 2 + 2 * math.pi * value;
      final markerPaint = Paint()
        ..color = AppColors.accent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2 * scale;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (outer + 1 * scale),
        center + dir * (outer - 21 * scale),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TickRingPainter old) =>
      old.value != value ||
      old.count != count ||
      old.idle != idle ||
      old.active != active ||
      old.showMarker != showMarker ||
      old.scale != scale;
}
