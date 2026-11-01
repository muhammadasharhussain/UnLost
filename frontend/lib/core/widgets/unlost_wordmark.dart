// lib/core/widgets/unlost_wordmark.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class UnlostWordmark extends StatefulWidget {
  final double fontSize;
  final bool animate;

  const UnlostWordmark({
    super.key,
    this.fontSize = 32,
    this.animate = false,
  });

  @override
  State<UnlostWordmark> createState() => _UnlostWordmarkState();
}

class _UnlostWordmarkState extends State<UnlostWordmark>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _strikeAnimation;
  Animation<double>? _unSlideAnimation;
  Animation<double>? _strikeFadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      );

      // 1. Strike line draws left to right: 0.0 to 0.45
      _strikeAnimation = CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      );

      // 2. "un" slides in from the left: 0.40 to 0.85
      _unSlideAnimation = CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
      );

      // 3. Strike line fades out: 0.75 to 1.0
      _strikeFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
        ),
      );

      _controller!.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final emerald = dark ? AppColors.emerald : AppColors.emeraldInk;
    final champagne = dark ? AppColors.champagne : AppColors.champagneInk;

    final unWidget = Text(
      'UN',
      style: TextStyle(
        fontFamily: AppTheme.brandFontFamily,
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w900,
        color: emerald,
        letterSpacing: -1.5,
      ),
    );

    final lostWidget = Text(
      'LOST',
      style: TextStyle(
        fontFamily: AppTheme.brandFontFamily,
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w900,
        color: champagne,
        letterSpacing: -1.5,
      ),
    );

    if (!widget.animate || reduceMotion || _controller == null) {
      return Semantics(
        label: 'Unlost',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              unWidget,
              lostWidget,
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Unlost',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            final strikeProgress = _strikeAnimation!.value;
            final unProgress = _unSlideAnimation!.value;
            final strikeOpacity = _strikeFadeAnimation!.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // "UN" slides in from left
                Opacity(
                  opacity: unProgress.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset((1.0 - unProgress) * -20.0, 0),
                    child: unWidget,
                  ),
                ),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    lostWidget,
                    // Thin emerald strike line through "LOST" that fades out
                    if (strikeOpacity > 0.01)
                      Positioned(
                        left: 0,
                        right: 0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Opacity(
                              opacity: strikeOpacity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 3.0,
                                  width: widget.fontSize * 1.8 * strikeProgress,
                                  decoration: BoxDecoration(
                                    color: emerald,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
