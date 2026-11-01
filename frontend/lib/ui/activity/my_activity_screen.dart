// lib/ui/activity/my_activity_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

import '../../core/matching/case_recommender.dart';
import '../../core/review_logic.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../data/models/claim_model.dart';
import '../../data/models/item_model.dart';
import '../../features/reviews/review_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/reviews_provider.dart';
import '../claims/finder_claim_confirm_card.dart';
import '../items/item_detail_screen.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  /// Loads my posts first, then the claims on those posts (needed for the
  /// progress tracker, finder-claim answers and review prompts).
  Future<void> _reload() async {
    if (!mounted) return;
    final items = context.read<ItemsProvider>();
    final claims = context.read<ClaimsProvider>();
    await items.loadMyItems();
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    await Future.wait([
      claims.loadMyClaims(),
      claims.loadClaimsForMyItems(items.myItems),
      if (userId != null && userId.isNotEmpty)
        context.read<ReviewsProvider>().loadForUser(userId),
    ]);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch when the logged-in user changes (e.g. demo account switcher).
    // IndexedStack keeps this widget alive, so initState won't re-fire.
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My activity',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                    color: p.text,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _buildTabs(context),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyPostsTab(context),
                  _buildMyClaimsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final p = context.palette;
    const labels = ['My posts', 'My claims'];

    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.circleFill,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: _tabController.index == i,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tabController.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tabController.index == i
                          ? p.invertedFill
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _tabController.index == i
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: -0.2,
                        color: _tabController.index == i
                            ? p.invertedText
                            : p.textDim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyPostsTab(BuildContext context) {
    final itemsProv = context.watch<ItemsProvider>();
    final auth = context.read<AuthProvider>();
    final viewerId = auth.currentUser?.id ?? '';
    final claimsProv = context.watch<ClaimsProvider>();
    final brightness = Theme.of(context).brightness;

    if (itemsProv.isLoadingMyItems) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (itemsProv.myItems.isEmpty) {
      return const EmptyStateView(
        icon: CupertinoIcons.tray,
        title: 'No posts yet',
        message:
            'Items you report as found or lost will show up here with their review status.',
      );
    }

    final cards = itemsProv.myItems.map((item) {
      final itemClaims = claimsProv.claimsOnMyItem(item.id);
      final awaitingMe = item.isLost
          ? itemClaims.where((c) => c.status == 'passed_to_finder').toList()
          : <ClaimModel>[];

      // Review prompt once the case is closed.
      Widget? reviewPrompt;
      if (item.isResolved) {
        final win = winningClaim(itemClaims);
        final target = win == null
            ? null
            : reviewTargetFor(item: item, claim: win, viewerId: viewerId);
        if (target != null) {
          reviewPrompt = ReviewPromptCard(
            caseId: target.caseId,
            viewerId: viewerId,
            aboutUserId: target.aboutUserId,
            aboutName: target.aboutName,
          );
        }
      }

      final extras = <Widget>[
        if (item.isRejected && item.rejectionReason != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Admin note: ${item.rejectionReason}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.readable(AppColors.error, brightness),
              ),
            ),
          ),
        for (final c in awaitingMe)
          FinderClaimConfirmCard(
            claim: c,
            onAnswered: (claim, isMine) async {
              if (!mounted) return;
              await afterFinderClaimAnswered(context, claim, isMine);
              if (mounted) await _reload();
            },
          ),
        ?reviewPrompt,
        if (item.isResolved)
          _ReceivedReviewSnippet(caseId: item.id, viewerId: viewerId),
      ];

      return CaseCard(
        item: item,
        claims: itemClaims,
        viewerId: viewerId,
        viewerIsAdmin: false,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
          );
          if (mounted) _reload();
        },
        extra: extras.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < extras.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    extras[i],
                  ],
                ],
              ),
      );
    }).toList();

    // Recommended: feed items that look like one of my active posts.
    final seen = <String>{};
    final recs = <Recommendation>[];
    for (final mine in itemsProv.myItems.where((i) => i.isActive)) {
      for (final r in CaseRecommender.recommend(mine, itemsProv.items)) {
        if (r.item.posterId != viewerId && seen.add(r.item.id)) recs.add(r);
      }
    }
    recs.sort((a, b) => b.score.compareTo(a.score));
    final topRecs = recs.take(3).toList();
    final p = context.palette;

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          if (topRecs.isNotEmpty) ...[
            Text(
              'RECOMMENDED FOR YOU',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Possible matches for your active posts. Only a possible match, never a confirmed one.',
              style: TextStyle(fontSize: 12.5, color: p.textDim),
            ),
            const SizedBox(height: 10),
            ResponsiveCardGrid(
              children: topRecs.map((r) {
                return CaseCard(
                  item: r.item,
                  viewerId: viewerId,
                  viewerIsAdmin: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: r.item.id)),
                  ),
                  extra: Text(
                    '${r.band == RecommendationBand.strong ? "Strong" : "Possible"} match: ${r.reasons.take(2).join(", ")}',
                    style: TextStyle(fontSize: 12, color: p.textDim),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Text(
              'YOUR POSTS',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: p.textDim,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ResponsiveCardGrid(children: cards),
        ],
      ),
    );
  }

  Widget _buildMyClaimsTab(BuildContext context) {
    final claimsProv = context.watch<ClaimsProvider>();
    final auth = context.read<AuthProvider>();
    final viewerId = auth.currentUser?.id ?? '';
    final p = context.palette;
    final brightness = Theme.of(context).brightness;

    if (claimsProv.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (claimsProv.myClaims.isEmpty) {
      return const EmptyStateView(
        icon: CupertinoIcons.shield_lefthalf_fill,
        title: 'No claims submitted',
        message:
            'When you claim an item from the campus feed, you can follow admin verification and finder approval here.',
      );
    }

    final cards = claimsProv.myClaims.map((claim) {
      // The card is item-shaped, so wrap the claim in a light item view.
      final item = ItemModel(
        id: claim.itemId,
        type: 'found',
        title: claim.itemTitle,
        category: claim.itemCategory,
        description: 'Your claim on this item.',
        area: 'My claim',
        dateTime: claim.createdAt,
        status: 'claim_pending',
        posterId: '',
        posterName: '',
        posterTrustScore: 0,
        createdAt: claim.createdAt,
      );
      final hasHandoverCode =
          (claim.status == 'handover_pending' || claim.status == 'approved') &&
              claim.handoverOtp != null &&
              claim.handoverOtp!.isNotEmpty;

      Widget? extra;
      if (hasHandoverCode) {
        extra = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                'YOUR PICKUP CODE',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: p.textDim,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                claim.handoverOtp!,
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5.0,
                  color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Read this aloud to the finder with your student ID.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, height: 1.35, color: p.textDim),
              ),
            ],
          ),
        );
      } else if (claim.isResolved || claim.status == 'approved') {
        extra = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClaimReviewPrompt(claim: claim, viewerId: viewerId),
            _ReceivedReviewSnippet(caseId: claim.itemId, viewerId: viewerId),
          ],
        );
      } else if (claim.isAwaitingAdmin) {
        extra = Row(
          children: [
            Icon(CupertinoIcons.hourglass,
                size: 14, color: AppColors.readable(AppColors.info, brightness)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Under admin verification first.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.readable(AppColors.info, brightness),
                ),
              ),
            ),
          ],
        );
      }

      return CaseCard(
        item: item,
        claimContext: claim,
        claims: [claim],
        viewerId: viewerId,
        viewerIsAdmin: false,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: claim.itemId)),
          );
        },
        extra: extra,
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [ResponsiveCardGrid(children: cards)],
      ),
    );
  }
}


/// On a closed claim (resolved, or approved on an item that is now returned),
/// loads the item to learn who the finder is, then shows the review prompt.
class _ClaimReviewPrompt extends StatefulWidget {
  final ClaimModel claim;
  final String viewerId;

  const _ClaimReviewPrompt({required this.claim, required this.viewerId});

  @override
  State<_ClaimReviewPrompt> createState() => _ClaimReviewPromptState();
}

class _ClaimReviewPromptState extends State<_ClaimReviewPrompt> {
  ReviewTarget? _target;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item =
          await context.read<ItemsProvider>().getItemById(widget.claim.itemId);
      final target = reviewTargetFor(
        item: item,
        claim: widget.claim,
        viewerId: widget.viewerId,
      );
      if (mounted) {
        setState(() {
          _target = target;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _target == null) return const SizedBox.shrink();
    return ReviewPromptCard(
      caseId: _target!.caseId,
      viewerId: widget.viewerId,
      aboutUserId: _target!.aboutUserId,
      aboutName: _target!.aboutName,
    );
  }
}

/// On a resolved case card, displays the review the viewer received (stars & quote) if one exists.
class _ReceivedReviewSnippet extends StatelessWidget {
  final String caseId;
  final String viewerId;

  const _ReceivedReviewSnippet({
    required this.caseId,
    required this.viewerId,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reviewsProv = context.watch<ReviewsProvider>();
    final userReviews = reviewsProv.reviewsFor(viewerId);
    final match = userReviews.where((r) => r.caseId == caseId).toList();
    if (match.isEmpty) return const SizedBox.shrink();

    final review = match.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FEEDBACK RECEIVED',
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: p.isDark ? AppColors.cerulean : AppColors.ceruleanInk,
                ),
              ),
              const Spacer(),
              StarRating(rating: review.rating, size: 12),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${review.comment.trim()}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: p.textDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
