// lib/ui/activity/my_activity_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/section_panel.dart';
import '../../data/models/claim_model.dart';
import '../../data/models/item_model.dart';
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
    final isDark = context.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final itemsProv = context.watch<ItemsProvider>();
    final claimsProv = context.watch<ClaimsProvider>();

    final viewerId = auth.currentUser?.id ?? '';
    final isAdmin = auth.currentUser?.isAdmin == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Pinned top title & segmented tabs (Posts / Claims)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Activity',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: p.panel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.panelBorder, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.hairline, width: 1),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: isDark ? AppColors.emerald : AppColors.emeraldInk,
                      unselectedLabelColor: p.textDim,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(text: 'My Posts (${itemsProv.myItems.length})'),
                        Tab(text: 'My Claims (${claimsProv.myClaims.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content structured into 3 SectionPanels: Needs action, In progress, Done
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(context, itemsProv.myItems, claimsProv, viewerId, isAdmin),
                  _buildClaimsTab(context, claimsProv.myClaims),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── POSTS TAB: Needs action / In progress / Done ─────────────────────────
  Widget _buildPostsTab(
    BuildContext context,
    List<ItemModel> posts,
    ClaimsProvider claimsProv,
    String viewerId,
    bool isAdmin,
  ) {
    if (posts.isEmpty) {
      return Center(
        child: SectionPanel(
          title: 'No posts yet',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Reports you create will appear here in panels.',
                style: TextStyle(color: context.palette.textDim, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    // 1. Needs action: pending finder claims awaiting my owner confirmation
    final pendingAwaitingOwner = <Widget>[];
    for (final item in posts) {
      final claims = claimsProv.claimsOnMyItem(item.id);
      for (final claim in claims) {
        if (claim.status == 'passed_to_finder') {
          pendingAwaitingOwner.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FinderClaimConfirmCard(claim: claim),
            ),
          );
        }
      }
    }

    // 2. In progress: active, pending_review, claim_pending, handover_pending
    final inProgressPosts = posts
        .where((i) =>
            i.status == 'active' ||
            i.status == 'pending_review' ||
            i.status == 'claim_pending' ||
            i.status == 'handover_pending')
        .toList();

    // 3. Done: resolved or rejected
    final donePosts = posts
        .where((i) => i.status == 'resolved' || i.status == 'rejected')
        .toList();

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          if (pendingAwaitingOwner.isNotEmpty)
            SectionPanel(
              title: 'Needs your action',
              subtitle: 'A finder submitted verification answers for your review',
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              customBorderColor: (context.isDarkMode ? AppColors.coral : AppColors.coralInk).withValues(alpha: 0.6),
              child: Column(children: pendingAwaitingOwner),
            ),
          SectionPanel(
            title: 'In progress (${inProgressPosts.length})',
            subtitle: 'Posts currently in review or actively matched',
            icon: CupertinoIcons.hourglass,
            child: inProgressPosts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('No posts in progress',
                          style: TextStyle(color: context.palette.textDim, fontSize: 12)),
                    ),
                  )
                : Column(
                    children: inProgressPosts.map((post) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CaseCard(
                          item: post,
                          viewerId: viewerId,
                          viewerIsAdmin: isAdmin,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(itemId: post.id),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),
          if (donePosts.isNotEmpty)
            SectionPanel(
              title: 'Done (${donePosts.length})',
              subtitle: 'Resolved or completed posts',
              icon: Icons.check_circle_outline_rounded,
              child: Column(
                children: donePosts.map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CaseCard(
                      item: post,
                      viewerId: viewerId,
                      viewerIsAdmin: isAdmin,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(itemId: post.id),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── CLAIMS TAB: Needs action / In progress / Done ────────────────────────
  Widget _buildClaimsTab(BuildContext context, List<ClaimModel> claims) {
    if (claims.isEmpty) {
      return Center(
        child: SectionPanel(
          title: 'No claims yet',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Claims you submit on found items appear here.',
                style: TextStyle(color: context.palette.textDim, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    final p = context.palette;
    final isDark = context.isDarkMode;

    final inProgressClaims = claims
        .where((c) =>
            c.status == 'awaiting_admin' ||
            c.status == 'passed_to_finder' ||
            c.status == 'approved' ||
            c.status == 'handover_pending')
        .toList();

    final doneClaims = claims
        .where((c) =>
            c.status == 'resolved' ||
            c.status == 'rejected' ||
            c.status == 'rejected_fake')
        .toList();

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          SectionPanel(
            title: 'In progress (${inProgressClaims.length})',
            subtitle: 'Claims being reviewed by admin or finder',
            icon: CupertinoIcons.arrow_2_squarepath,
            child: inProgressClaims.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('No active claims in progress',
                          style: TextStyle(color: p.textDim, fontSize: 12)),
                    ),
                  )
                : Column(
                    children: inProgressClaims.map((claim) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.hairline, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Claim #${claim.id.replaceAll(RegExp(r'[^0-9]'), '')}',
                                  style: TextStyle(
                                    fontFamily: AppTheme.monoFontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.champagne : AppColors.champagneInk)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    claim.status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: AppTheme.monoFontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.champagne : AppColors.champagneInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Target Item ID: ${claim.itemId}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          if (doneClaims.isNotEmpty)
            SectionPanel(
              title: 'Done (${doneClaims.length})',
              subtitle: 'Resolved claims',
              icon: Icons.check_circle_outline_rounded,
              child: Column(
                children: doneClaims.map((claim) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.hairline, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          claim.status == 'resolved'
                              ? Icons.celebration_rounded
                              : Icons.cancel_outlined,
                          size: 20,
                          color: claim.status == 'resolved'
                              ? (isDark ? AppColors.emerald : AppColors.emeraldInk)
                              : AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Claim #${claim.id.replaceAll(RegExp(r'[^0-9]'), '')} — ${claim.status.replaceAll('_', ' ')}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
