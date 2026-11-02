// lib/core/widgets/case_progress.dart
import 'package:flutter/material.dart' hide StepState;
import '../case_progress_logic.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CaseProgressView extends StatefulWidget {
  final CaseProgress progress;

  const CaseProgressView({super.key, required this.progress});

  @override
  State<CaseProgressView> createState() => _CaseProgressViewState();
}

class _CaseProgressViewState extends State<CaseProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showHowItWorksSheet(BuildContext context, UnlostPalette p, bool dark) {
    // 7 canonical stages explained:
    // 1. Posted: Item submitted to UnLost
    // 2. Admin review: Admin checks the post is genuine
    // 3. Claim or Found: A student claims the item or finder posts a match
    // 4. Admin verifies answers: Admin verifies the security answers
    // 5. Owner/finder confirms: Owner or finder approves the match
    // 6. Handover (pickup code): High-value items receive a 6-digit code
    // 7. Returned: Handover complete, case closed
    final stages = [
      (
        title: 'Posted',
        desc: 'Item submitted to UnLost with description and location.',
        icon: Icons.post_add_rounded,
        matchLabels: ['POSTED', 'SUBMITTED', 'MESSAGE', 'SENT'],
      ),
      (
        title: 'Admin review',
        desc: 'Admin checks the post is genuine and protects against spam.',
        icon: Icons.admin_panel_settings_rounded,
        matchLabels: ['REVIEW', 'QUEUE', 'ADMIN OK'],
      ),
      (
        title: 'Claim or Found',
        desc: 'A student files a claim with answers, or finder reports a match.',
        icon: Icons.search_rounded,
        matchLabels: ['OPEN', 'CLAIM', 'FOUND HIT', 'CLAIMS'],
      ),
      (
        title: 'Admin verifies answers',
        desc: 'Admin verifies the private answers against stored details.',
        icon: Icons.verified_user_rounded,
        matchLabels: ['ADMIN', 'ADMIN REVIEW'],
      ),
      (
        title: 'Owner/finder confirms',
        desc: 'Owner or finder confirms the claimant and coordinates.',
        icon: Icons.handshake_rounded,
        matchLabels: ['FINDER', 'OWNER', 'CONFIRMED', 'APPROVED', 'POST OK'],
      ),
      (
        title: 'Handover (pickup code)',
        desc: 'Parties meet publicly; claimant reads secret 6-digit code.',
        icon: Icons.pin_rounded,
        matchLabels: ['HANDOVER', 'OTP CODE'],
      ),
      (
        title: 'Returned',
        desc: 'Item safely returned to rightful owner. Case closed!',
        icon: Icons.celebration_rounded,
        matchLabels: ['RETURNED', 'RESOLVE'],
      ),
    ];

    // Determine current stage index in stages list based on current active step
    final currentStep = widget.progress.steps.firstWhere(
      (s) => s.state == StepState.current,
      orElse: () => widget.progress.steps.last,
    );
    final currentLabel = currentStep.label.toUpperCase();

    int activeStageIndex = 0;
    for (int i = 0; i < stages.length; i++) {
      if (stages[i].matchLabels.any((l) => currentLabel.contains(l))) {
        activeStageIndex = i;
        break;
      }
    }
    if (widget.progress.steps.every((s) => s.state == StepState.done)) {
      activeStageIndex = stages.length - 1;
    }

    final cardBg = dark ? AppColors.darkCard : AppColors.lightCard;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final emerald = dark ? AppColors.emerald : AppColors.emeraldInk;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textFaint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.help_outline_rounded, color: emerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How It Works',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        Text(
                          '7 Verification Stages from Report to Return',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFontFamily,
                            fontSize: 10,
                            color: p.textFaint,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: p.textDim, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),

              // List of stages
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  shrinkWrap: true,
                  itemCount: stages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = stages[idx];
                    final isHere = idx == activeStageIndex;
                    final isDone = idx < activeStageIndex;

                    final itemBorderColor = isHere
                        ? emerald
                        : (isDone ? border : border.withValues(alpha: 0.5));

                    final itemBg = isHere
                        ? emerald.withValues(alpha: dark ? 0.12 : 0.08)
                        : (dark ? AppColors.darkSurface : AppColors.lightSurface);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: itemBorderColor, width: isHere ? 1.5 : 1.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHere
                                  ? emerald
                                  : (isDone ? emerald.withValues(alpha: 0.2) : border.withValues(alpha: 0.3)),
                            ),
                            child: Icon(
                              item.icon,
                              size: 16,
                              color: isHere
                                  ? (dark ? AppColors.onEmerald : Colors.white)
                                  : (isDone ? emerald : p.textFaint),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${idx + 1}. ${item.title}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isHere ? (dark ? AppColors.emerald : AppColors.emeraldInk) : p.text,
                                      ),
                                    ),
                                    if (isHere) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (dark ? AppColors.coral : AppColors.coralInk).withValues(alpha: dark ? 0.25 : 0.20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'YOU ARE HERE',
                                          style: TextStyle(
                                            fontFamily: AppTheme.monoFontFamily,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: dark ? AppColors.coral : AppColors.coralInk,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.desc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: p.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final doneColor = dark ? AppColors.emerald : AppColors.emeraldInk;
    final currentColor = dark ? AppColors.champagne : AppColors.champagneInk;
    final pendingColor = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final errorColor = dark ? AppColors.error : AppColors.errorInk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segmented bar with tooltips and Semantics
        Row(
          children: widget.progress.steps.map((step) {
            Color segColor;
            String stateDesc;
            switch (step.state) {
              case StepState.done:
                segColor = doneColor;
                stateDesc = 'completed';
                break;
              case StepState.current:
                segColor = currentColor;
                stateDesc = 'current stage (you are here)';
                break;
              case StepState.rejected:
                segColor = errorColor;
                stateDesc = 'rejected';
                break;
              case StepState.pending:
                segColor = pendingColor;
                stateDesc = 'pending';
                break;
            }

            final isCurrent = step.state == StepState.current && !reduceMotion;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Tooltip(
                  message: '${step.label}: $stateDesc',
                  child: Semantics(
                    label: 'Stage ${step.label}: $stateDesc',
                    child: isCurrent
                        ? AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) => Container(
                              height: 4.0,
                              decoration: BoxDecoration(
                                color: segColor.withValues(alpha: _pulseAnimation.value),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: segColor.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            height: 4.0,
                            decoration: BoxDecoration(
                              color: segColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // One line of plain text stating status & action + "?" button
        Row(
          children: [
            Expanded(
              child: Text(
                widget.progress.statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.progress.isRejected
                      ? (dark ? AppColors.error : AppColors.errorInk)
                      : context.palette.textDim,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'How it works: explanation of case stages',
              child: InkWell(
                onTap: () => _showHowItWorksSheet(context, context.palette, dark),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: dark ? AppColors.coral : AppColors.coralInk,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
