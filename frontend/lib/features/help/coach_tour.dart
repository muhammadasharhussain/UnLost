// lib/features/help/coach_tour.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'help_nudge.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });
}

class TourController {
  static const String prefKey = 'coach_tour_completed_v1';
  static bool sessionTourActive = false;

  static final GlobalKey dockKey = GlobalKey(debugLabel: 'tour_dock');
  static final GlobalKey searchKey = GlobalKey(debugLabel: 'tour_search');
  static final GlobalKey postKey = GlobalKey(debugLabel: 'tour_post');
  static final GlobalKey helpKey = GlobalKey(debugLabel: 'tour_help');

  static Future<bool> shouldShowTour() async {
    if (sessionTourActive) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(prefKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleted() async {
    sessionTourActive = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
      await prefs.setBool(HelpNudge.prefKey, true);
    } catch (_) {}
  }

  static void start(
    BuildContext context, {
    required bool isAdmin,
    VoidCallback? onComplete,
  }) {
    final steps = isAdmin
        ? [
            TourStep(
              targetKey: dockKey,
              title: 'Navigation Dock',
              description: 'Switch quickly between Review Queues, Browse feed, and Admin Profile.',
            ),
            TourStep(
              targetKey: searchKey,
              title: 'Search & Filters',
              description: 'Filter posts by keyword, category, or status instantly.',
            ),
            TourStep(
              targetKey: postKey,
              title: 'Audit & Overview',
              description: 'Track campus return statistics and system-wide verification health.',
            ),
            TourStep(
              targetKey: helpKey,
              title: 'Admin Help Desk',
              description: 'Campus admin guide and automated verification support.',
            ),
          ]
        : [
            TourStep(
              targetKey: dockKey,
              title: 'Navigation Dock',
              description: 'Switch between the campus Browse feed, My Activity tracker, and Profile.',
            ),
            TourStep(
              targetKey: searchKey,
              title: 'Smart Search',
              description: 'Search lost and found items across campus by category and keywords.',
            ),
            TourStep(
              targetKey: postKey,
              title: 'Post Item',
              description: 'Report lost possessions or items you found with 2 verification questions.',
            ),
            TourStep(
              targetKey: helpKey,
              title: 'Unlost Assistant',
              description: 'Tap Help anytime for chatbot guidance, claiming rules, and OTP handover tips.',
            ),
          ];

    sessionTourActive = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) => CoachTourOverlay(
        steps: steps,
        onDone: () async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await markCompleted();
          onComplete?.call();
        },
      ),
    );
  }
}

class CoachTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onDone;

  const CoachTourOverlay({
    super.key,
    required this.steps,
    required this.onDone,
  });

  @override
  State<CoachTourOverlay> createState() => _CoachTourOverlayState();
}

class _CoachTourOverlayState extends State<CoachTourOverlay> {
  int _currentStep = 0;

  Rect? _getTargetRect(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext == null) return null;
    final renderBox = currentContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final step = widget.steps[_currentStep];
    final rect = _getTargetRect(step.targetKey);
    final size = MediaQuery.of(context).size;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final targetCenter = rect != null ? rect.center : Offset(size.width / 2, size.height / 2);
    final isTargetInTopHalf = targetCenter.dy < size.height / 2;

    return Semantics(
      label: 'Tour step ${_currentStep + 1} of ${widget.steps.length}: ${step.title}. ${step.description}',
      child: Stack(
        children: [
          // Dim background with cutout
          CustomPaint(
            size: size,
            painter: _CutoutPainter(
              targetRect: rect,
              overlayColor: Colors.black.withValues(alpha: p.isDark ? 0.78 : 0.65),
            ),
          ),

          // Dismiss tap catcher outside target
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _next,
            ),
          ),

          // Tour card
          Positioned(
            left: 20,
            right: 20,
            top: isTargetInTopHalf ? math.min(size.height - 220, (rect?.bottom ?? targetCenter.dy) + 20) : null,
            bottom: !isTargetInTopHalf ? math.min(size.height - 220, size.height - (rect?.top ?? targetCenter.dy) + 20) : null,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP ${_currentStep + 1} / ${widget.steps.length}',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onDone,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFontFamily,
                              fontSize: 12,
                              color: p.textDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: p.textDim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: Text(
                          _currentStep < widget.steps.length - 1 ? 'Next' : 'Got it',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onCerulean,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  const _CutoutPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect == null) {
      canvas.drawPath(backgroundPath, Paint()..color = overlayColor);
      return;
    }

    final paddedRect = targetRect!.inflate(6);
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(paddedRect, const Radius.circular(16)));

    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(combinedPath, Paint()..color = overlayColor);

    // Subtle highlight border around the cut-out
    final borderPaint = Paint()
      ..color = AppColors.cerulean
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddedRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter old) =>
      old.targetRect != targetRect || old.overlayColor != overlayColor;
}
