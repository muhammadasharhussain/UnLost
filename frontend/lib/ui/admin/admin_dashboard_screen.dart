// lib/ui/admin/admin_dashboard_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/matching/match_scorer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/match_highlight.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_panel.dart';
import '../../core/widgets/trust_score_badge.dart';
import '../../data/models/claim_model.dart';
import '../../data/models/item_model.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminDashboardScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRejectPostDialog(ItemModel item) {
    String selectedReason = AppConstants.postRejectionReasons.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: const Text('Reject Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select the reason for rejection (this will be shown to the poster):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...AppConstants.postRejectionReasons.map((reason) {
                final isSelected = selectedReason == reason;
                return ListTile(
                  title: Text(reason, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  trailing: isSelected ? const Icon(CupertinoIcons.checkmark_alt, size: 16, color: AppColors.primary) : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    setDialogState(() => selectedReason = reason);
                  },
                );
              }),
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
                await context
                    .read<AdminProvider>()
                    .rejectPost(item.id, selectedReason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Reject Post', style: TextStyle(color: AppColors.onRose)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectClaimDialog(ClaimModel claim, {required bool asFake}) {
    String selectedReason = AppConstants.claimRejectionReasons.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(asFake ? 'Reject Claim as FAKE' : 'Reject Claim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (asFake)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'DANGER: Rejecting as fake will dock the student\'s trust score by 20 points.',
                    style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ),
              const Text(
                'Select rejection reason:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...AppConstants.claimRejectionReasons.map((reason) {
                final isSelected = selectedReason == reason;
                return ListTile(
                  title: Text(reason, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  trailing: isSelected ? const Icon(CupertinoIcons.checkmark_alt, size: 16, color: AppColors.primary) : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    setDialogState(() => selectedReason = reason);
                  },
                );
              }),
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
                final adminProv = context.read<AdminProvider>();
                if (asFake) {
                  await adminProv.rejectClaimAsFake(claim.id, selectedReason);
                } else {
                  await adminProv.rejectClaim(claim.id, selectedReason);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(
                asFake ? 'Confirm Fake' : 'Reject',
                style: const TextStyle(color: AppColors.onRose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminProv = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.isEmbedded ? 'Review Queues' : 'Campus Admin Area',
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        automaticallyImplyLeading: !widget.isEmbedded,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(CupertinoIcons.arrow_left),
                onPressed: () => Navigator.pop(context),
              ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Posts Queue'),
                  if (adminProv.pendingPosts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${adminProv.pendingPosts.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onCerulean,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Claims Queue'),
                  if (adminProv.pendingClaims.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${adminProv.pendingClaims.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onCerulean,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsQueueTab(context),
          _buildClaimsQueueTab(context),
        ],
      ),
    );
  }

  Widget _buildPostsQueueTab(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final posts = adminProv.pendingPosts;

    return Column(
      children: [
        // Filter Chips Bar (All / Found / Lost)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildTypeFilterChip(
                label: 'All Posts',
                filter: 'all',
                current: adminProv.postTypeFilter,
                onTap: () => adminProv.setPostTypeFilter('all'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                label: 'Found Posts',
                filter: 'found',
                current: adminProv.postTypeFilter,
                onTap: () => adminProv.setPostTypeFilter('found'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeFilterChip(
                label: 'Lost Reports',
                filter: 'lost',
                current: adminProv.postTypeFilter,
                onTap: () => adminProv.setPostTypeFilter('lost'),
                isDark: isDark,
              ),
            ],
          ),
        ),

        Expanded(
          child: adminProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : posts.isEmpty
                  ? const EmptyStateView(
                      icon: CupertinoIcons.checkmark_seal_fill,
                      title: 'Queue is Clear',
                      message: 'No pending student posts awaiting verification review.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => adminProv.loadAdminData(),
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          SectionPanel(
                            title: 'Posts Queue (${posts.length})',
                            subtitle: 'Student reports awaiting administrative approval',
                            icon: CupertinoIcons.shield_fill,
                            child: Column(
                              children: posts.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _postReviewCard(item, adminProv, isDark),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _postReviewCard(ItemModel item, AdminProvider adminProv, bool isDark) {
    final p = context.palette;
    return CaseCard(
      item: item,
      viewerId: 'admin',
      viewerIsAdmin: true,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Posted by ${item.posterName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.textDim),
                ),
              ),
              TrustScoreBadge(score: item.posterTrustScore, isCompact: true),
            ],
          ),
          if (item.isFound && item.hiddenFields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Poster verification answers',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.text),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(item.hiddenFields.length, (idx) {
                    return Text(
                      '${idx + 1}. ${item.hiddenFields[idx]}',
                      style: TextStyle(fontSize: 11.5, color: p.textDim),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Approve',
              icon: CupertinoIcons.checkmark_alt,
              onPressed: () => adminProv.approvePost(item.id),
              variant: ButtonVariant.glow,
              height: 44,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Reject',
              icon: CupertinoIcons.xmark,
              onPressed: () => _showRejectPostDialog(item),
              variant: ButtonVariant.glowGlass,
              height: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required String filter,
    required String current,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = filter == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.onCerulean : context.palette.text,
          ),
        ),
      ),
    );
  }

  Widget _buildClaimsQueueTab(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final claims = adminProv.pendingClaims;

    if (adminProv.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (claims.isEmpty) {
      return const EmptyStateView(
        icon: CupertinoIcons.shield_lefthalf_fill,
        title: 'No Pending Claims',
        message: 'All submitted claims have been reviewed by campus administrators.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => adminProv.loadAdminData(),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          SectionPanel(
            title: 'Claims Queue (${claims.length})',
            subtitle: 'Verification answers awaiting administrative review',
            icon: CupertinoIcons.checkmark_shield_fill,
            child: Column(
              children: claims.map((claim) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _claimReviewCard(claim, adminProv, isDark),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimReviewCard(ClaimModel claim, AdminProvider adminProv, bool isDark) {
    final isFinderMessage = claim.isFinderClaim;
    final item = ItemModel(
      id: claim.itemId,
      type: isFinderMessage ? 'lost' : 'found',
      title: isFinderMessage ? 'Finder message on a LOST report: ${claim.itemTitle}' : 'Claim: ${claim.itemTitle}',
      category: claim.itemCategory,
      description: isFinderMessage
          ? 'Finder ${claim.claimantName} reports finding this lost item.'
          : 'Claim submitted by ${claim.claimantName}.',
      area: 'Claim review',
      dateTime: claim.createdAt,
      status: 'claim_pending',
      posterId: '',
      posterName: '',
      posterTrustScore: 0,
      createdAt: claim.createdAt,
    );
    return CaseCard(
      item: item,
      claimContext: claim,
      claims: [claim],
      viewerId: 'admin',
      viewerIsAdmin: true,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                // Claimant Info & Trust
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(claim.claimantName.isNotEmpty ? claim.claimantName[0] : 'U'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      claim.claimantName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TrustScoreBadge(score: claim.claimantTrustScore, isCompact: true),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Match Band Chip & Low Confidence Warning ──
                Builder(builder: (context) {
                  final result = MatchScorer.score(
                    finderAnswers: claim.finderAnswers,
                    claimantAnswers: claim.answers,
                    category: claim.itemCategory,
                  );
                  final bandColor = result.band == MatchBand.strong
                      ? AppColors.success
                      : (result.band == MatchBand.partial
                          ? (isDark ? AppColors.emerald : AppColors.emeraldInk)
                          : (isDark ? AppColors.champagne : AppColors.champagneInk));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: bandColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: bandColor, width: 1.2),
                            ),
                            child: Text(
                              '${result.band.label.toUpperCase()} MATCH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: bandColor,
                              ),
                            ),
                          ),
                          if (result.isLowConfidence) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Low confidence: not enough unique details',
                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

                // ── Side-by-Side Finder Answers vs Claimant Answers ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFinderMessage
                            ? 'Stored owner report vs finder message:'
                            : 'Stored Finder Answers vs Claimant Answers:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      MatchComparisonBlock(
                        finderAnswers: claim.finderAnswers,
                        claimantAnswers: claim.answers,
                        category: claim.itemCategory,
                        finderLabel: isFinderMessage ? 'Owner report' : 'Stored finder answer',
                        claimantLabel: isFinderMessage ? 'Finder message' : 'Claimant answer',
                      ),
                    ],
                  ),
                ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Pass',
              icon: CupertinoIcons.arrow_right_circle_fill,
              onPressed: () => adminProv.passClaim(claim.id),
              variant: ButtonVariant.glow,
              height: 44,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Reject',
              icon: CupertinoIcons.xmark,
              onPressed: () => _showRejectClaimDialog(claim, asFake: false),
              variant: ButtonVariant.glowGlass,
              height: 44,
            ),
          ),
          IconButton(
            tooltip: 'Reject as fake (lowers trust)',
            onPressed: () => _showRejectClaimDialog(claim, asFake: true),
            icon: const Icon(CupertinoIcons.flag_fill, color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}
