// lib/core/widgets/glow_pill_button.dart
//
// Soft glowing pill button (indigo to lavender, glassy edge, coloured glow),
// matching the "Review Claim" reference. Tones: violet (main action),
// glass (secondary, same shape) and danger.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum GlowTone { violet, glass, danger }

class GlowPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlowTone tone;
  final double height;
  final double? width;
  final bool isLoading;

  const GlowPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = GlowTone.violet,
    this.height = 48,
    this.width,
    this.isLoading = false,
  });

  @override
  State<GlowPillButton> createState() => _GlowPillButtonState();
}

class _GlowPillButtonState extends State<GlowPillButton> {
  bool _hover = false, _down = false;

  // Colours picked so white text stays readable where the label sits
  // (the middle of the gradient is at least about 4.5:1 against white).
  static const _violet = [Color(0xFF4F46E5), Color(0xFF7C5CF0), Color(0xFFA98BFB)];
  static const _danger = [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFF87171)];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final glass = widget.tone == GlowTone.glass;
    final colors = widget.tone == GlowTone.danger ? _danger : _violet;
    final glow = widget.tone == GlowTone.danger
        ? const Color(0xFFDC2626)
        : const Color(0xFF6A5AF0);
    final fg = glass ? p.text : Colors.white;
    final r = BorderRadius.circular(widget.height / 2);

    final decoration = glass
        ? BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: p.isDark
                  ? const [Color(0x22FFFFFF), Color(0x0AFFFFFF)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF1F1F8)],
            ),
            border: Border.all(
              color: _hover
                  ? const Color(0xFF7C5CF0).withValues(alpha: 0.7)
                  : (p.isDark ? const Color(0x33FFFFFF) : const Color(0xFFD5D5E2)),
            ),
          )
        : BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0, 0.55, 1],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: _hover ? 0.50 : 0.34),
                blurRadius: _hover ? 28 : 22,
                offset: const Offset(0, 10),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.5 : 1,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.width,
            height: widget.height,
            decoration: decoration,
            child: ClipRRect(
              borderRadius: r,
              child: Stack(
                children: [
                  if (!glass)
                    // Soft top-left light, gives the glassy "lit from inside" feel.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.7, -1.2),
                              radius: 1.3,
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: enabled ? widget.onPressed : null,
                      onHover: (v) => setState(() => _hover = v),
                      onHighlightChanged: (v) => setState(() => _down = v),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(widget.icon, size: 18, color: fg),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Text(
                                        widget.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: fg,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
