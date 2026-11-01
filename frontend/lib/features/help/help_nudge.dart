// lib/features/help/help_nudge.dart
// One-time "New here? Tap Help" bubble that sits above the Help button on
// first launch. The "seen" flag lives in shared_preferences (wrapped in
// try/catch). A session flag stops it from reappearing if storage fails.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class HelpNudge extends StatefulWidget {
  /// Builds the Help button. Call [dismissNudge] when the user taps it.
  final Widget Function(BuildContext context, VoidCallback dismissNudge) builder;

  const HelpNudge({super.key, required this.builder});

  /// Shared preference key (also handy for tests).
  static const String prefKey = 'help_nudge_seen_v1';

  /// Set after the nudge was shown once in this app session.
  static bool _handledThisSession = false;

  @override
  State<HelpNudge> createState() => _HelpNudgeState();
}

class _HelpNudgeState extends State<HelpNudge> {
  bool _visible = false;
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (HelpNudge._handledThisSession) return;

    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(HelpNudge.prefKey) ?? false;
    } catch (_) {
      seen = false; // storage unavailable: fall back to the session flag only
    }
    if (seen) {
      HelpNudge._handledThisSession = true;
      return;
    }

    _showTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      HelpNudge._handledThisSession = true;
      setState(() => _visible = true);
      _hideTimer = Timer(const Duration(seconds: 10), _dismiss);
    });
  }

  Future<void> _markSeen() async {
    HelpNudge._handledThisSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(HelpNudge.prefKey, true);
    } catch (_) {
      // Ignore: the session flag already prevents a repeat.
    }
  }

  void _dismiss() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (mounted && _visible) setState(() => _visible = false);
    _markSeen();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final accent = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;
    final bg = p.isDark ? AppColors.darkCard : AppColors.lightCard;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: duration,
            child: AnimatedSlide(
              offset: _visible || reduceMotion ? Offset.zero : const Offset(0, 0.25),
              duration: duration,
              curve: Curves.easeOut,
              child: _visible
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Semantics(
                        liveRegion: true,
                        label: 'New here? Tap Help',
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accent, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'New here? Tap Help',
                                      style: TextStyle(
                                        fontFamily: AppTheme.monoFontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: p.text,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Semantics(
                                      button: true,
                                      label: 'Dismiss tip',
                                      child: Icon(Icons.close_rounded,
                                          size: 18, color: p.textDim),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Little tail pointing down at the Help button.
                            Positioned(
                              bottom: -7,
                              right: 34,
                              child: Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    border: Border(
                                      right: BorderSide(color: accent, width: 1.5),
                                      bottom: BorderSide(color: accent, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        widget.builder(context, _dismiss),
      ],
    );
  }
}
