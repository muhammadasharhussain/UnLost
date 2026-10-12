// lib/ui/activity/my_activity_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dot_matrix_text.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/hover_color_icon.dart';
import '../../core/widgets/status_pill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/items_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().loadMyItems();
      context.read<ClaimsProvider>().loadMyClaims();
    });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ItemsProvider>().loadMyItems();
        context.read<ClaimsProvider>().loadMyClaims();
      });
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
    final p = context.palette;

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

    return RefreshIndicator(
      onRefresh: () => itemsProv.loadMyItems(),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: itemsProv.myItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = itemsProv.myItems[index];
          final cat = ItemCategories.getById(item.category);
          final dateStr = DateFormat('MMM d, h:mm a').format(item.dateTime);
          final typeColor = AppColors.readable(
            item.isFound ? AppColors.success : AppColors.warning,
            Theme.of(context).brightness,
          );

          return GlassCard(
            padding: const EdgeInsets.all(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(itemId: item.id),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.isDark
                            ? AppColors.darkCardSubtle
                            : AppColors.lightCardSubtle,
                      ),
                      child: HoverColorIcon(
                        icon: cat.icon,
                        size: 19,
                        activeColor:
                            item.isFound ? AppColors.success : AppColors.warning,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.isFound ? 'Found' : 'Lost'} · ${cat.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11.5, color: p.textFaint),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(status: item.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.area,
                  style: TextStyle(fontSize: 13, color: p.textDim),
                ),
                if (item.isRejected && item.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Admin note: ${item.rejectionReason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.readable(
                          AppColors.error,
                          Theme.of(context).brightness,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyClaimsTab(BuildContext context) {
    final claimsProv = context.watch<ClaimsProvider>();
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

    return RefreshIndicator(
      onRefresh: () => claimsProv.loadMyClaims(),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: claimsProv.myClaims.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final claim = claimsProv.myClaims[index];
          final dateStr = DateFormat('MMM d, h:mm a').format(claim.createdAt);
          final hasHandoverCode =
              (claim.status == 'handover_pending' || claim.status == 'approved') &&
                  claim.handoverOtp != null &&
                  claim.handoverOtp!.isNotEmpty;

          return GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11.5, color: p.textFaint),
                    ),
                    StatusPill(status: claim.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  claim.itemTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${ItemCategories.getById(claim.itemCategory).name}',
                  style: TextStyle(fontSize: 13, color: p.textDim),
                ),

                // Handover pickup code, shown as a dot-matrix readout.
                if (hasHandoverCode) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    tone: CardTone.indigo,
                    radius: 28,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.lock_shield_fill,
                                  size: 15, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(
                                'Your pickup code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: DotMatrixText(
                              claim.handoverOtp!,
                              dotSize: 6,
                              gap: 2.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Read this code aloud to the finder once you show your student ID.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (claim.isAwaitingAdmin) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.hourglass,
                          size: 15,
                          color: AppColors.readable(AppColors.info, brightness),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Under admin verification. It goes to the finder once approved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.readable(AppColors.info, brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
