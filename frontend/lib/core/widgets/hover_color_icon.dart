// lib/core/widgets/hover_color_icon.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable icon widget fulfilling requirement 4.3:
/// - Desktop / Web: Pointer-hover animates monochrome black/white icon into full color.
/// - Mobile / Touch: Graceful tap animation briefly fills the color (200ms) before executing action.
class HoverColorIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color activeColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final String? tooltip;

  const HoverColorIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.activeColor = AppColors.primary,
    this.onTap,
    this.padding = const EdgeInsets.all(8.0),
    this.isSelected = false,
    this.tooltip,
  });

  @override
  State<HoverColorIcon> createState() => _HoverColorIconState();
}

class _HoverColorIconState extends State<HoverColorIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant HoverColorIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else if (!_isHovered) {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onExit(PointerEvent _) {
    setState(() => _isHovered = false);
    if (!widget.isSelected) {
      _controller.reverse();
    }
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;

    // Mobile / Touch behavior: provide graceful color fill bounce
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 60));
      if (!widget.isSelected && mounted) {
        _controller.reverse();
      }
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monochromeColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    Widget child = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap != null ? _handleTap : null,
        child: Padding(
          padding: widget.padding,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              // Interpolate between theme monochrome and vibrant active color
              final currentColor = Color.lerp(
                monochromeColor,
                widget.activeColor,
                _animation.value,
              )!;

              // Scale slightly on hover/active (1.0 -> 1.1)
              final scale = 1.0 + (_animation.value * 0.08);

              return Transform.scale(
                scale: scale,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: currentColor,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      child = Tooltip(
        message: widget.tooltip!,
        child: child,
      );
    }

    return child;
  }
}
