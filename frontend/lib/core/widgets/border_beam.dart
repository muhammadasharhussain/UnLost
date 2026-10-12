// lib/core/widgets/border_beam.dart
//
// Flutter version of the "border-beam" effect: a short, colourful light that
// travels around the edge of a rounded shape. It follows the shape's real
// outline, so the beam has the same length on the long and short sides of a
// pill (a plain SweepGradient would stretch on wide shapes).
import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';

/// Colours the beam passes through, head to tail.
const List<Color> kBeamColors = [
  Color(0xFF06B6D4), // cyan (tail)
  Color(0xFFA855C7), // violet
  Color(0xFFEC4899), // pink
  Color(0xFFF4E22C), // lemon (head)
];

class BorderBeam extends StatefulWidget {
  final Widget child;
  final double radius;
  final double strokeWidth;

  /// One lap around the border. The reference uses about 3.1 seconds.
  final Duration duration;

  /// Beam length as a share of the whole outline (0..1).
  final double beamFraction;
  final List<Color> colors;

  /// Colour of the always-visible hairline under the beam.
  final Color baseBorder;

  /// Fill behind the child.
  final Color fill;

  /// false = hairline only, beam hidden and animation stopped. Buttons use
  /// this to animate on hover, focus or press only.
  final bool animate;

  const BorderBeam({
    super.key,
    required this.child,
    required this.radius,
    required this.baseBorder,
    required this.fill,
    this.strokeWidth = 1.5,
    this.duration = const Duration(milliseconds: 3100),
    this.beamFraction = 0.22,
    this.colors = kBeamColors,
    this.animate = true,
  });

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  bool _reduceMotion = false;

  void _sync() {
    final run = widget.animate && !_reduceMotion;
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _sync();
  }

  @override
  void didUpdateWidget(covariant BorderBeam old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBeam = widget.animate && !_reduceMotion;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BeamPainter(
          progress: _c,
          radius: widget.radius,
          stroke: widget.strokeWidth,
          fraction: widget.beamFraction,
          colors: widget.colors,
          base: widget.baseBorder,
          fill: widget.fill,
          showBeam: showBeam,
        ),
        child: widget.child,
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  final Animation<double> progress;
  final double radius, stroke, fraction;
  final List<Color> colors;
  final Color base, fill;
  final bool showBeam;

  _BeamPainter({
    required this.progress,
    required this.radius,
    required this.stroke,
    required this.fraction,
    required this.colors,
    required this.base,
    required this.fill,
    required this.showBeam,
  }) : super(repaint: progress);

  static const int _segments = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(radius, size.shortestSide / 2);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );

    // Fill + hairline border.
    canvas.drawRRect(rrect, Paint()..color = fill);
    final inset = rrect.deflate(0.5);
    canvas.drawRRect(
      inset,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = base,
    );
    if (!showBeam) return;

    final path = Path()..addRRect(rrect.deflate(stroke / 2));
    final PathMetric metric = path.computeMetrics().first;
    final total = metric.length;
    final beamLen = total * fraction;
    final head = progress.value * total;

    final seg = beamLen / _segments;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (var i = 0; i < _segments; i++) {
      // t = 0 at the tail, 1 at the head.
      final t = (i + 1) / _segments;
      final start = head - beamLen + i * seg;
      final end = start + seg * 1.15; // slight overlap hides seams
      final color = _sample(t);
      final alpha = math.pow(t, 1.6).toDouble(); // tail fades out
      line.color = color.withValues(alpha: alpha);
      _drawWrapped(canvas, metric, total, start, end, line);
      if (i % 3 == 0) {
        glow.color = color.withValues(alpha: alpha * 0.45);
        _drawWrapped(canvas, metric, total, start, end + seg * 2, glow);
      }
    }
  }

  void _drawWrapped(Canvas canvas, PathMetric m, double total, double a,
      double b, Paint p) {
    // Normalise into [0, total) and split when the piece crosses the start.
    double s = a % total;
    if (s < 0) s += total;
    final len = b - a;
    final e = s + len;
    if (e <= total) {
      canvas.drawPath(m.extractPath(s, e), p);
    } else {
      canvas.drawPath(m.extractPath(s, total), p);
      canvas.drawPath(m.extractPath(0, e - total), p);
    }
  }

  Color _sample(double t) {
    final pos = t * (colors.length - 1);
    final i = pos.floor().clamp(0, colors.length - 2);
    return Color.lerp(colors[i], colors[i + 1], pos - i)!;
  }

  @override
  bool shouldRepaint(covariant _BeamPainter o) =>
      o.radius != radius ||
      o.stroke != stroke ||
      o.fraction != fraction ||
      o.base != base ||
      o.fill != fill ||
      o.showBeam != showBeam ||
      o.colors != colors;
}
