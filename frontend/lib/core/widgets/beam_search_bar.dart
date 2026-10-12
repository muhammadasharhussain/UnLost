// lib/core/widgets/beam_search_bar.dart
//
// Search bar and button surface built on [BorderBeam].
// Reference spec: dark pill #1D1D1D, 1px inset border (44,47,54 at 52%),
// 42px high, "Search" placeholder, beam lap of about 3.1 seconds.
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'border_beam.dart';

/// Colours shared by the search bar and beam buttons.
class BeamColors {
  static const Color darkFill = Color(0xFF1D1D1D);
  static const Color darkBorder = Color(0x852C2F36); // 52% of #2C2F36
  static const Color lightFill = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDADBE1);

  // Placeholder: the reference #565656 is only 2.3:1 on #1D1D1D, so we use a
  // lighter grey (about 5:1) to keep it readable.
  static const Color darkHint = Color(0xFF8E8E96);
  static const Color lightHint = Color(0xFF6B6B73);

  static Color fill(bool dark) => dark ? darkFill : lightFill;
  static Color border(bool dark) => dark ? darkBorder : lightBorder;
  static Color hint(bool dark) => dark ? darkHint : lightHint;
}

class BeamSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;
  final double height;

  const BeamSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hint = 'Search',
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = p.isDark;
    final textColor = dark ? const Color(0xFFF6F6F3) : const Color(0xFF0E0E11);
    final r = height / 2;

    return SizedBox(
      height: height,
      child: BorderBeam(
        radius: r,
        fill: BeamColors.fill(dark),
        baseBorder: BeamColors.border(dark),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(CupertinoIcons.search, size: 18, color: BeamColors.hint(dark)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: textColor,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle:
                      TextStyle(fontSize: 15, color: BeamColors.hint(dark)),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox(width: 16)
                  : IconButton(
                      tooltip: 'Clear search',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(CupertinoIcons.clear_circled_solid,
                          size: 18, color: BeamColors.hint(dark)),
                      onPressed: onClear,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark pill button with a hairline border. The beam runs while the button is
/// hovered, focused or pressed, so a screen with many buttons stays cheap.
class BeamSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final String? semanticLabel;

  const BeamSurface({
    super.key,
    required this.child,
    required this.onPressed,
    this.height = 54,
    this.width,
    this.semanticLabel,
  });

  @override
  State<BeamSurface> createState() => _BeamSurfaceState();
}

class _BeamSurfaceState extends State<BeamSurface> {
  bool _hover = false, _focus = false, _down = false;

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: FocusableActionDetector(
            enabled: enabled,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onShowHoverHighlight: (v) => setState(() => _hover = v),
            onShowFocusHighlight: (v) => setState(() => _focus = v),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed?.call();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: enabled ? (_) => setState(() => _down = true) : null,
              onTapCancel: () => setState(() => _down = false),
              onTapUp: (_) => setState(() => _down = false),
              onTap: widget.onPressed,
              child: BorderBeam(
                radius: widget.height / 2,
                fill: BeamColors.fill(dark),
                baseBorder: BeamColors.border(dark),
                animate: enabled && (_hover || _focus || _down),
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFF6F6F3)
                          : const Color(0xFF0E0E11),
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: dark
                            ? const Color(0xFFF6F6F3)
                            : const Color(0xFF0E0E11),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
