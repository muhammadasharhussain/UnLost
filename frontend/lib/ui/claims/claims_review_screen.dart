// lib/ui/claims/claims_review_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/trust_score_badge.dart';
import '../../data/models/claim_model.dart';
import '../../providers/claims_provider.dart';
import '../chat/chat_screen.dart';
import 'handover_screen.dart';
import '../../core/widgets/app_backdrop.dart';

class ClaimsReviewScreen extends StatefulWidget {
  final String itemId;

  const ClaimsReviewScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<ClaimsReviewScreen> createState() => _ClaimsReviewScreenState();
}

class _ClaimsReviewScreenState extends State<ClaimsReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClaimsProvider>().loadClaimsForItem(widget.itemId);
    });
  }

  void _showRejectDialog(ClaimModel claim) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: const Text('Reject Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rejecting this claim will notify the claimant that their answers did not match the item. This does NOT negatively impact their trust score.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Optional reason (e.g. key details did not match)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final claimsProv = context.read<ClaimsProvider>();
              await claimsProv.rejectClaim(
                claim.id,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject Claim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportFakeDialog(ClaimModel claim) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Report as Fake Claim'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WARNING: Reporting a claim as fraudulent or malicious will reduce the student\'s community trust score by 15 points. Repeated fake claims result in an automatic account suspension.',
              style: TextStyle(fontSize: 13, color: AppColors.error, height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Describe why this claim is deceptive...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final claimsProv = context.read<ClaimsProvider>();
              await claimsProv.reportFake(
                claim.id,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : 'Reported as fraudulent or deceptive claim.',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveClaim(ClaimModel claim) async {
    final claimsProv = context.read<ClaimsProvider>();
    final success = await claimsProv.approveClaim(claim.id);

    if (success && mounted) {
      if (claim.isHighValue) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HandoverScreen(claimId: claim.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              claimId: claim.id,
              recipientName: claim.claimantName,
            ),
          ),
        );
      }
    }
  }

  void _showSideBySideComparison(ClaimModel c1, ClaimModel c2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Side-by-Side Answer Comparison',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Both claims are close matches. Compare their answers to make an informed choice.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Header with names
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c1.claimantName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c2.claimantName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Answers 1
                  const Text('Question 1 Answers:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c1.answers.isNotEmpty ? c1.answers[0] : 'No answer',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c2.answers.isNotEmpty ? c2.answers[0] : 'No answer',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Answers 2
                  const Text('Question 2 Answers:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c1.answers.length > 1 ? c1.answers[1] : 'No answer',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c2.answers.length > 1 ? c2.answers[1] : 'No answer',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimsProv = context.watch<ClaimsProvider>();
    final claims = claimsProv.itemClaims;

    return AppBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Review Claims'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: claimsProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : claims.isEmpty
              ? const EmptyStateView(
                  icon: CupertinoIcons.doc_checkmark,
                  title: 'No Verified Claims Yet',
                  message:
                      'Claims submitted by other students will appear here once approved by campus administration.',
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Top Explanation Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.shield_lefthalf_fill,
                              size: 20, color: AppColors.info),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Only admin-passed claims appear here. They are ranked by verification match strength.',
                              style: TextStyle(fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Close Match Warning & Side-by-Side Comparison Option
                    if (claims.length >= 2 &&
                        (claims[0].matchScore - claims[1].matchScore).abs() <= 12) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_triangle_fill,
                                    size: 18, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text(
                                  'Close Match Alert',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'The top 2 claimants provided very similar answers. Compare them side-by-side before approving.',
                              style: TextStyle(fontSize: 12, height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showSideBySideComparison(claims[0], claims[1]),
                              child: const Text(
                                'Compare Answers Side-by-Side →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Claims List (Ranked recommendation)
                    ...List.generate(claims.length, (index) {
                      final claim = claims[index];
                      final isTopRecommended = index == 0 &&
                          (claim.status == 'passed_to_finder' ||
                              claim.status == 'approved');

                      return _buildClaimCard(context, claim, isTopRecommended);
                    }),
                  ],
                ),
    ),
    );
  }

  Widget _buildClaimCard(
      BuildContext context, ClaimModel claim, bool isTopRecommended) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Match Strength Meter Representation (not raw % dumped)
    Color matchColor;
    double progress;
    if (claim.matchScore >= 80) {
      matchColor = AppColors.success;
      progress = 0.95;
    } else if (claim.matchScore >= 55) {
      matchColor = AppColors.warning;
      progress = 0.65;
    } else {
      matchColor = AppColors.error;
      progress = 0.35;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopRecommended
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isTopRecommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Claimant Name, Trust Score, Status / Recommended Badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: Text(
                  claim.claimantName.isNotEmpty ? claim.claimantName[0] : 'U',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.claimantName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    TrustScoreBadge(
                      score: claim.claimantTrustScore,
                      isCompact: true,
                    ),
                  ],
                ),
              ),
              if (isTopRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.sparkles, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                StatusPill(status: claim.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 16),

          // Match Strength Indicator (Strength Meter + Context Label)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Match Strength:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      claim.matchStrength,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: matchColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: matchColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(matchColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Claimant's Submitted Answers
          Text(
            'Claimant\'s Answers:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(claim.answers.length, (idx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}. ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Expanded(
                    child: Text(
                      claim.answers[idx],
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 18),

          // Action Buttons
          if (claim.status == 'passed_to_finder') ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    icon: CupertinoIcons.checkmark_alt,
                    onPressed: () => _approveClaim(claim),
                    variant: ButtonVariant.primary,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _showRejectDialog(claim),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Report Fake',
                  onPressed: () => _showReportFakeDialog(claim),
                  icon: const Icon(CupertinoIcons.flag_fill,
                      size: 18, color: AppColors.error),
                ),
              ],
            ),
          ] else if (claim.status == 'handover_pending') ...[
            CustomButton(
              text: 'Complete Handover Verification',
              icon: CupertinoIcons.lock_shield_fill,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HandoverScreen(claimId: claim.id),
                  ),
                );
              },
              variant: ButtonVariant.primary,
              height: 44,
            ),
          ] else if (claim.status == 'approved') ...[
            CustomButton(
              text: 'Open Chat',
              icon: CupertinoIcons.chat_bubble_2_fill,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      claimId: claim.id,
                      recipientName: claim.claimantName,
                    ),
                  ),
                );
              },
              variant: ButtonVariant.secondary,
              height: 44,
            ),
          ],
        ],
      ),
    );
  }
}
