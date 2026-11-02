// lib/core/widgets/section_panel.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Reusable SectionPanel widget:
/// - Distinct surface colour (panel tier between bg and card)
/// - Subtle border
/// - Rounded container (16-20px)
/// - Small header: title + subtitle + optional "See all" action
/// - Inner padding
/// - Outer horizontal margins (16px) and vertical spacing (12-16px)
/// Keeps the animated grid backdrop visible around and between panels.
class SectionPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? customPanelColor;
  final Color? customBorderColor;

  const SectionPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.onActionTap,
    this.actionLabel,
    required this.child,
    this.padding,
    this.margin,
    this.customPanelColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;

    final panelBg = customPanelColor ??
        (isDark ? AppColors.darkPanel : AppColors.lightPanel);
    final borderColor = customBorderColor ??
        (isDark ? AppColors.darkPanelBorder : AppColors.lightPanelBorder);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Panel Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: p.text,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: p.textDim,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null)
                    action!
                  else if (actionLabel != null && onActionTap != null)
                    InkWell(
                      onTap: onActionTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionLabel!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.emerald
                                    : AppColors.emeraldInk,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark
                                  ? AppColors.emerald
                                  : AppColors.emeraldInk,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Panel Content
            Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
