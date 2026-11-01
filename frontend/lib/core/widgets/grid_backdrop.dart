// lib/core/widgets/grid_backdrop.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class GridBackdrop extends StatefulWidget {
  final Widget child;

  const GridBackdrop({super.key, required this.child});

  @override
  State<GridBackdrop> createState() => _GridBackdropState();
}

class _GridBackdropState extends State<GridBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _driftAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Smooth up-and-down loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _driftAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations && _controller.isAnimating) {
      _controller.stop();
    } else if (!disableAnimations && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: disableAnimations
              ? CustomPaint(
                  painter: _GridPainter(
                    dark: dark,
                    verticalOffsetProgress: 0.0,
                  ),
                  size: Size.infinite,
                )
              : AnimatedBuilder(
                  animation: _driftAnimation,
                  builder: (context, _) => CustomPaint(
                    painter: _GridPainter(
                      dark: dark,
                      verticalOffsetProgress: _driftAnimation.value,
                    ),
                    size: Size.infinite,
                  ),
                ),
        ),
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool dark;
  final double verticalOffsetProgress;

  const _GridPainter({
    required this.dark,
    required this.verticalOffsetProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Base colour
    canvas.drawRect(
      rect,
      Paint()..color = dark ? AppColors.darkBg : AppColors.lightBg,
    );

    // 2. Faint champagne glow in the centre-top and soft emerald ambient glow
    final glowChampagne = RadialGradient(
      center: const Alignment(0.0, -0.6),
      radius: 1.1,
      colors: [
        (dark ? AppColors.champagne : AppColors.champagneInk)
            .withValues(alpha: dark ? 0.09 : 0.06),
        Colors.transparent,
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = glowChampagne);

    final glowEmerald = RadialGradient(
      center: const Alignment(0.7, 0.7),
      radius: 1.2,
      colors: [
        (dark ? AppColors.emerald : AppColors.emeraldInk)
            .withValues(alpha: dark ? 0.08 : 0.05),
        Colors.transparent,
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = glowEmerald);

    // 3. Emerald Grid lines (44px cells) moving smoothly up and down
    const double cellSize = 44.0;
    // Oscillate vertically by 1 cell (44 px) up and down
    final double verticalShift = (verticalOffsetProgress - 0.5) * cellSize;

    final gridPaint = Paint()
      ..color = (dark ? AppColors.emerald : AppColors.emeraldInk)
          .withValues(alpha: dark ? 0.09 : 0.11)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical lines (fixed horizontally)
    for (double x = 0; x <= w + cellSize; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Horizontal lines (moving up and down smoothly)
    final double startY = (verticalShift % cellSize) - cellSize;
    for (double y = startY; y <= h + cellSize; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Small junction crosses with subtle champagne shimmer at every 2nd intersection
    final junctionPaint = Paint()
      ..color = (dark ? AppColors.champagne : AppColors.champagneInk)
          .withValues(alpha: dark ? 0.15 : 0.18)
      ..strokeWidth = 1.2;

    for (double x = cellSize; x < w; x += cellSize * 2) {
      for (double y = startY; y < h; y += cellSize * 2) {
        canvas.drawLine(Offset(x - 2, y), Offset(x + 2, y), junctionPaint);
        canvas.drawLine(Offset(x, y - 2), Offset(x, y + 2), junctionPaint);
      }
    }

    // 4. Subtle Vignette so grid fades smoothly at edges
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        (dark ? AppColors.darkBg : AppColors.lightBg).withValues(alpha: 0.65),
      ],
      stops: const [0.65, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vignette);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.dark != dark ||
        oldDelegate.verticalOffsetProgress != verticalOffsetProgress;
  }
}
