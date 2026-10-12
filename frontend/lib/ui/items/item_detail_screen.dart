// lib/ui/items/item_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/hover_color_icon.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/trust_score_badge.dart';
import '../../data/models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/items_provider.dart';
import '../claims/claim_form_screen.dart';
import '../claims/claims_review_screen.dart';
import 'post_found_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ItemModel? _item;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final itemsProv = context.read<ItemsProvider>();
      final item = await itemsProv.getItemById(widget.itemId);
      if (!mounted) return;
      final claimsProv = context.read<ClaimsProvider>();
      await claimsProv.loadClaimsForItem(widget.itemId);

      if (mounted) {
        setState(() {
          _item = item;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final claimsProv = context.watch<ClaimsProvider>();
    final currentUser = auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null || _item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 40, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_error ?? 'Item details unavailable'),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Retry',
                  width: 140,
                  height: 40,
                  onPressed: _loadItem,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _item!;
    final isMyPost = currentUser != null && currentUser.id == item.posterId;
    final cat = ItemCategories.getById(item.category);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(item.dateTime);
    final isHighVal = ItemCategories.isHighValueCategory(item.category);

    final itemClaims = claimsProv.itemClaims;
    final pendingFinderClaims = itemClaims
        .where((c) => c.status == 'passed_to_finder')
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusPill(status: item.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Surface (Fintech-inspired rounded highlight card)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardSubtle
                              : AppColors.lightCardSubtle,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: HoverColorIcon(
                          icon: cat.icon,
                          size: 24,
                          activeColor: item.isFound
                              ? AppColors.success
                              : AppColors.warning,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: item.isFound
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isHighVal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.lock_fill,
                                  size: 11, color: AppColors.warning),
                              SizedBox(width: 4),
                              Text(
                                'High Value',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location & Date Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Location',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                            Text(
                              item.area,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reported Date & Time',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Poster Profile & Community Trust Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Text(
                      item.posterName.isNotEmpty ? item.posterName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyPost ? 'You (Poster)' : item.posterName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Community Trust Member',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TrustScoreBadge(score: item.posterTrustScore),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Private Verification Answers (Visible ONLY to Post's Own Finder!) ──
            if (isMyPost && item.isFound && item.hiddenFields.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.eye_slash_fill,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Your Private Verification Answers',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'These answers are hidden from the public and used to verify incoming claims.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(item.hiddenFields.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${idx + 1}. ',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            Expanded(
                              child: Text(
                                item.hiddenFields[idx],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Context-Aware Action Banners & Buttons (Section 6 Checklist) ──────

            // Case 1: My own found post, still pending admin review
            if (isMyPost && item.isPendingReview) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.hourglass,
                        size: 22, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your post is currently under review by campus administrators. Once verified, it will be published to the campus feed.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Case 2: My post rejected by admin
            if (isMyPost && item.isRejected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.xmark_circle_fill,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Post Rejected by Administrator',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${item.rejectionReason ?? "Insufficient item details"}',
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],

            // Admin Read-Only Notice
            if (currentUser?.isAdmin == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.eye_fill, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Read-only admin preview. Post/claim actions and chat entry points are restricted to students.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Case 3: My own found post, approved and active -> "Review Claims" button
            if (isMyPost && !currentUser.isAdmin && item.isFound && (item.isActive || item.isHandoverPending)) ...[
              CustomButton(
                text: pendingFinderClaims.isNotEmpty
                    ? 'Review Claims (${pendingFinderClaims.length} pending)'
                    : 'View All Claims',
                icon: CupertinoIcons.doc_checkmark_fill,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClaimsReviewScreen(itemId: item.id),
                    ),
                  );
                },
                variant: ButtonVariant.primary,
              ),
            ],

            // Case 4: My own found post, resolved -> "Returned" state banner
            if (isMyPost && item.isResolved) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill,
                        size: 22, color: AppColors.success),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This item has been successfully returned and resolved. Thank you for making our campus safer!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Case 5: Someone else's approved found post, open -> "This is mine" claim button
            if (!isMyPost && currentUser?.isAdmin != true && item.isFound && item.isActive) ...[
              CustomButton(
                text: 'This is Mine (Claim Item)',
                icon: CupertinoIcons.shield_lefthalf_fill,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClaimFormScreen(item: item),
                    ),
                  );
                },
                variant: ButtonVariant.primary,
              ),
            ],

            // Case 6: Someone else's found post, claim in progress or handover pending
            if (!isMyPost && item.isFound && (item.isClaimPending || item.isHandoverPending)) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill,
                        size: 22, color: AppColors.info),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A claim is currently in progress or awaiting handover for this item. New claims are temporarily paused.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Case 7: Someone else's lost post -> "I found this" button pre-filling Post Found flow
            if (!isMyPost && currentUser?.isAdmin != true && item.isLost && item.isActive) ...[
              CustomButton(
                text: 'I Found This Item',
                icon: CupertinoIcons.hand_raised_fill,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostFoundScreen(
                        initialCategory: item.category,
                        initialTitle: 'Found: ${item.title}',
                        initialArea: item.area,
                      ),
                    ),
                  );
                },
                variant: ButtonVariant.primary,
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
