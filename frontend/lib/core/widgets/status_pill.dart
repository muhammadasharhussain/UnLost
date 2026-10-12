// lib/core/widgets/status_pill.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status;
  final String? customLabel;
  final bool isCompact;

  const StatusPill({
    super.key,
    required this.status,
    this.customLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending_review':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        icon = CupertinoIcons.hourglass;
        label = customLabel ?? 'Under Review';
        break;
      case 'awaiting_admin':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        icon = CupertinoIcons.shield_lefthalf_fill;
        label = customLabel ?? 'Awaiting Admin';
        break;
      case 'passed_to_finder':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        icon = CupertinoIcons.person_crop_circle_badge_checkmark;
        label = customLabel ?? 'Passed to Finder';
        break;
      case 'active':
      case 'approved':
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = CupertinoIcons.checkmark_circle_fill;
        label = customLabel ?? 'Approved';
        break;
      case 'claim_pending':
        bg = AppColors.purpleBg;
        fg = AppColors.purple;
        icon = CupertinoIcons.doc_text_search;
        label = customLabel ?? 'Claim in Review';
        break;
      case 'handover_pending':
        bg = const Color(0x1AF97316);
        fg = const Color(0xFFEA580C);
        icon = CupertinoIcons.lock_shield_fill;
        label = customLabel ?? 'Handover Pending';
        break;
      case 'resolved':
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = CupertinoIcons.check_mark_circled;
        label = customLabel ?? 'Returned / Resolved';
        break;
      case 'rejected':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        icon = CupertinoIcons.xmark_circle_fill;
        label = customLabel ?? 'Rejected';
        break;
      case 'rejected_fake':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        label = customLabel ?? 'Flagged as Fake';
        break;
      default:
        bg = brightness == Brightness.dark
            ? AppColors.darkCardSubtle
            : AppColors.lightCardSubtle;
        fg = brightness == Brightness.dark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
        icon = CupertinoIcons.info_circle;
        label = customLabel ?? status;
    }

    final tint = fg;
    fg = AppColors.readable(fg, brightness);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
