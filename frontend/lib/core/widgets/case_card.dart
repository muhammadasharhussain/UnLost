// lib/core/widgets/case_card.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/item_model.dart';
import '../../data/models/claim_model.dart';
import '../case_progress_logic.dart';
import '../constants/categories.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'case_progress.dart';
import 'hover_color_icon.dart';

class CaseCard extends StatefulWidget {
  final ItemModel item;
  final List<ClaimModel> claims;
  final ClaimModel? claimContext;
  final String viewerId;
  final bool viewerIsAdmin;
  final VoidCallback? onTap;

  /// Optional content shown under the description (e.g. admin review details).
  final Widget? extra;

  /// Optional action area at the bottom of the card (e.g. Approve / Reject).
  final Widget? footer;

  const CaseCard({
    super.key,
    required this.item,
    this.claims = const [],
    this.claimContext,
    required this.viewerId,
    required this.viewerIsAdmin,
    this.onTap,
    this.extra,
    this.footer,
  });

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final isFound = widget.item.isFound;
    final isResolved = widget.item.isResolved;

    // Top color bar: Found = emerald, Lost = champagne
    final Color topBarColor = isResolved
        ? (dark ? AppColors.darkBorder : AppColors.lightBorder)
        : (isFound
            ? (dark ? AppColors.emerald : AppColors.emeraldInk)
            : (dark ? AppColors.champagne : AppColors.champagneInk));

    // Dynamic case number from id: "Case #1", "Case #2" without leading zeros
    final String caseNumber = _formatCaseNumber(widget.item.id);
    final String timeStr = DateFormat('MMM d, h:mm a').format(widget.item.dateTime);

    final progress = progressFor(
      item: widget.item,
      claims: widget.claims,
      claimContext: widget.claimContext,
      viewerId: widget.viewerId,
      viewerIsAdmin: widget.viewerIsAdmin,
    );

    final double scale = reduceMotion
        ? 1.0
        : (_isPressed
            ? 0.98
            : (_isHovered ? 1.03 : 1.0));

    final Color bgColor = _isHovered
        ? (dark ? AppColors.darkCardHover : AppColors.lightCardHover)
        : (dark ? AppColors.darkCard : AppColors.lightCard);

    final Color borderColor = _isHovered
        ? (dark ? AppColors.emerald : AppColors.emeraldInk)
        : (dark ? AppColors.darkBorder : AppColors.lightBorder);

    final List<BoxShadow> shadows = _isHovered && !reduceMotion
        ? [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: dark ? 0.22 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : const [];

    return Semantics(
      label: '${isFound ? "Found" : "Lost"} item: ${widget.item.title}, ${progress.statusText}',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 2.0,
                ),
                boxShadow: shadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top colour bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: _isHovered && !reduceMotion ? 6.0 : 3.0,
                      color: topBarColor,
                    ),

                    Expanded(
                     child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Header: Icon Box + Case Number / Category
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Outlined square icon box
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: dark ? AppColors.darkBorder : AppColors.lightBorder,
                                    width: 1.5,
                                  ),
                                  color: dark ? AppColors.darkSurface : AppColors.lightSurface,
                                ),
                                child: Center(
                                  child: HoverColorIcon(
                                    icon: ItemCategories.getById(widget.item.category).icon,
                                     size: 20,
                                     activeColor: topBarColor,
                                     padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    caseNumber,
                                    style: TextStyle(
                                      fontFamily: AppTheme.monoFontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: topBarColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.category.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: AppTheme.monoFontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: context.palette.textFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Serif Title
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: context.palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Dim Description (2 lines)
                          Text(
                            widget.item.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: context.palette.textDim,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.extra != null) ...[
                            const SizedBox(height: 12),
                            widget.extra!,
                          ],
                          const SizedBox(height: 14),
                          ],
                         ),
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Hairline Divider
                          Divider(
                            color: dark ? AppColors.darkBorder : AppColors.lightBorder,
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),

                          // Progress tracker
                          CaseProgressView(progress: progress),
                          const SizedBox(height: 12),

                          // Bottom Row: Tags (area, time) and Arrow
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 12,
                                color: context.palette.textFaint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${widget.item.area.toUpperCase()} • $timeStr',
                                  style: TextStyle(
                                    fontFamily: AppTheme.monoFontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: context.palette.textFaint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedSlide(
                                offset: Offset(_isHovered && !reduceMotion ? 0.25 : 0.0, 0),
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  CupertinoIcons.arrow_right,
                                  size: 15,
                                  color: _isHovered
                                      ? (dark ? AppColors.emerald : AppColors.emeraldInk)
                                      : context.palette.textFaint,
                                ),
                              ),
                            ],
                          ),
                          if (widget.footer != null) ...[
                            const SizedBox(height: 14),
                            widget.footer!,
                          ],
                          ],
                         ),
                        ],
                      ),
                     ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCaseNumber(String id) {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      final code = (id.hashCode.abs() % 100) + 1;
      return 'Case #$code';
    }
    final num = int.tryParse(digits) ?? 1;
    return 'Case #$num';
  }
}

