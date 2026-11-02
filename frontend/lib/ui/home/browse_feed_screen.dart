// lib/ui/home/browse_feed_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/beam_search_bar.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/section_panel.dart';
import '../../core/widgets/unlost_wordmark.dart';
import '../../data/models/item_model.dart';
import '../../features/help/coach_tour.dart';
import '../../features/help/help_bot_engine.dart';
import '../../features/help/help_bot_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/reviews_provider.dart';
import '../activity/my_activity_screen.dart';
import '../items/item_detail_screen.dart';
import '../items/post_found_screen.dart';
import '../items/post_lost_screen.dart';
import '../items/see_all_items_screen.dart';

class BrowseFeedScreen extends StatefulWidget {
  const BrowseFeedScreen({super.key});

  @override
  State<BrowseFeedScreen> createState() => _BrowseFeedScreenState();
}

class _BrowseFeedScreenState extends State<BrowseFeedScreen> {
  bool _showFirstRunHint = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<ItemsProvider>().searchQuery;
    _searchController = TextEditingController(text: initialQuery);
    _checkFirstRunHint();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstRunHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('seen_what_happened_hint') ?? false;
      if (!seen && mounted) {
        setState(() => _showFirstRunHint = true);
      }
    } catch (_) {}
  }

  Future<void> _dismissFirstRunHint() async {
    setState(() => _showFirstRunHint = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_what_happened_hint', true);
    } catch (_) {}
  }

  void _openHelpBot(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().currentUser?.isAdmin == true;
    HelpBotSheet.show(
      context,
      contextData: HelpContext(
        role: isAdmin ? 'admin' : 'student',
        currentScreen: 'home',
      ),
      onAction: (act) {
        if (act == 'nav_post') {
          _navigateToLostOrFound(context);
        } else if (act == 'start_tour') {
          TourController.start(context, isAdmin: isAdmin);
        }
      },
    );
  }

  void _navigateToLostOrFound(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: context.isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Report to Campus Feed',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to report?',
                style: TextStyle(fontSize: 13, color: context.palette.textDim),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: context.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.search, color: AppColors.champagneInk),
                ),
                title: const Text('I lost something', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Describe what was lost so finders can match it', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PostLostScreen()));
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: context.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.hand_draw_fill,
                    color: context.isDarkMode ? AppColors.coral : AppColors.coralInk,
                  ),
                ),
                title: const Text('I found something', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Post it with secret questions to safely return it', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PostFoundScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final itemsProv = context.watch<ItemsProvider>();
    final claimsProv = context.watch<ClaimsProvider>();
    final reviewsProv = context.watch<ReviewsProvider>();

    final user = auth.currentUser;
    final firstName = user != null ? user.name.split(' ').first : 'there';
    final viewerId = user?.id ?? '';
    final isAdmin = user?.isAdmin == true;

    // Attention items: pending claims awaiting owner confirmation
    final totalAttention = claimsProv.totalFinderClaimsAwaitingOwner;

    // Recent items: up to 3 cards
    final recentItems = itemsProv.items.take(3).toList();
    // Recently returned items
    final returnedItems = itemsProv.items.where((i) => i.status == 'resolved').take(3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── PINNED COMPACT HEADER ───────────────────────────────────────
            _buildPinnedHeader(context, firstName, isDark, p, itemsProv),
            // ── SCROLLABLE PANEL AREA ──────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    itemsProv.loadItems(),
                    reviewsProv.loadReunions(),
                  ]);
                },
                color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    if (isWide) {
                      return _buildWideLayout(
                        context,
                        itemsProv,
                        recentItems,
                        returnedItems,
                        totalAttention,
                        viewerId,
                        isAdmin,
                      );
                    }
                    return _buildSingleColumnLayout(
                      context,
                      itemsProv,
                      recentItems,
                      returnedItems,
                      totalAttention,
                      viewerId,
                      isAdmin,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PINNED HEADER: Wordmark, greeting, search, help button ────────────────
  Widget _buildPinnedHeader(
    BuildContext context,
    String firstName,
    bool isDark,
    UnlostPalette p,
    ItemsProvider itemsProv,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: BoxDecoration(
            color: p.bg.withValues(alpha: 0.85),
            border: Border(bottom: BorderSide(color: p.hairline.withValues(alpha: 0.5), width: 1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const UnlostWordmark(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '• Hi $firstName',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        color: p.textDim,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                    tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                    onTap: () => context
                        .read<ThemeProvider>()
                        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    tooltip: 'Ask UnLost Help Bot',
                    onTap: () => _openHelpBot(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BeamSearchBar(
                controller: _searchController,
                onChanged: itemsProv.onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  itemsProv.clearSearch();
                },
                hint: 'Search lost bags, student cards, keys...',
              ),
            ],
          ),
        ),
        // Thin progress bar shown during background refreshes (stale-while-revalidate)
        if (itemsProv.isRefreshing)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: p.panelBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.emerald : AppColors.emeraldInk,
            ),
          ),
      ],
    );
  }

  // ── MOBILE / SINGLE-COLUMN SECTIONED PANELS ──────────────────────────────
  Widget _buildSingleColumnLayout(
    BuildContext context,
    ItemsProvider itemsProv,
    List<ItemModel> recentItems,
    List<ItemModel> returnedItems,
    int totalAttention,
    String viewerId,
    bool isAdmin,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 90),
      children: [
        // 1. "What happened?" panel (primary inDrive style task panel)
        _buildWhatHappenedPanel(context),

        // 2. "Needs your attention" panel (only when active actions exist)
        if (totalAttention > 0) _buildAttentionPanel(context, totalAttention),

        // 3. "Recent on campus" panel with filter chips and at most 3 cards
        _buildRecentOnCampusPanel(context, itemsProv, recentItems, viewerId, isAdmin),

        // 4. "Recently returned" panel
        _buildRecentlyReturnedPanel(context, returnedItems, viewerId, isAdmin),
      ],
    );
  }

  // ── WIDE SCREEN (>= 900px): Two columns of panels ────────────────────────
  Widget _buildWideLayout(
    BuildContext context,
    ItemsProvider itemsProv,
    List<ItemModel> recentItems,
    List<ItemModel> returnedItems,
    int totalAttention,
    String viewerId,
    bool isAdmin,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (What happened + Recent items)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildWhatHappenedPanel(context),
                  _buildRecentOnCampusPanel(context, itemsProv, recentItems, viewerId, isAdmin),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Column (Attention + Recently returned)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  if (totalAttention > 0)
                    _buildAttentionPanel(context, totalAttention),
                  _buildRecentlyReturnedPanel(context, returnedItems, viewerId, isAdmin),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── PANEL 1: "What happened?" (inDrive task-first flow) ───────────────────
  Widget _buildWhatHappenedPanel(BuildContext context) {
    final isDark = context.isDarkMode;
    final p = context.palette;

    return SectionPanel(
      title: 'What happened?',
      subtitle: 'Open it, tell us what happened, done.',
      icon: CupertinoIcons.sparkles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showFirstRunHint) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.coral : AppColors.coralInk).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? AppColors.coral : AppColors.coralInk).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.hand_point_right_fill,
                    size: 16,
                    color: isDark ? AppColors.coral : AppColors.coralInk,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start here! Tap whether you lost or found something.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _dismissFirstRunHint,
                    child: Icon(Icons.close_rounded, size: 16, color: p.textDim),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _TaskBigButton(
                  title: 'I lost something',
                  subtitle: 'Get help finding it',
                  icon: CupertinoIcons.search,
                  badgeColor: isDark ? AppColors.champagne : AppColors.champagneInk,
                  bgColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  textColor: p.text,
                  isActionPrimary: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostLostScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TaskBigButton(
                  title: 'I found something',
                  subtitle: 'Return to owner',
                  icon: CupertinoIcons.hand_draw_fill,
                  badgeColor: isDark ? AppColors.coral : AppColors.coralInk,
                  bgColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  textColor: p.text,
                  isActionPrimary: true, // Exactly one primary action highlighted
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostFoundScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PANEL 2: "Needs your attention" ──────────────────────────────────────
  Widget _buildAttentionPanel(BuildContext context, int count) {
    final isDark = context.isDarkMode;

    return SectionPanel(
      title: 'Needs your attention',
      subtitle: '$count claim requires your review or confirmation',
      icon: CupertinoIcons.exclamationmark_circle_fill,
      customBorderColor: (isDark ? AppColors.coral : AppColors.coralInk).withValues(alpha: 0.6),
      actionLabel: 'View',
      onActionTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyActivityScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.coral : AppColors.coralInk).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.coral : AppColors.coralInk,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ACTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.onCoral : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pending student answers await verification.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PANEL 3: "Recent on campus" (max 3 preview cards + See all) ──────────
  Widget _buildRecentOnCampusPanel(
    BuildContext context,
    ItemsProvider itemsProv,
    List<ItemModel> recentItems,
    String viewerId,
    bool isAdmin,
  ) {
    return SectionPanel(
      title: 'Recent on campus',
      subtitle: 'Verified campus lost and found items',
      icon: CupertinoIcons.clock,
      actionLabel: 'See all (${itemsProv.items.length})',
      onActionTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeeAllItemsScreen(
              title: 'All campus items',
              items: itemsProv.items,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips inside panel with clear visual icons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'Found reports',
                  icon: CupertinoIcons.checkmark_shield_fill,
                  isSelected: itemsProv.activeType == 'found',
                  onTap: () => itemsProv.setActiveType('found'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Lost reports',
                  icon: CupertinoIcons.search,
                  isSelected: itemsProv.activeType == 'lost',
                  onTap: () => itemsProv.setActiveType('lost'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (recentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No verified items found matching this filter.'),
              ),
            )
          else
            // Cards live strictly inside the panel (max 3)
            ...recentItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CaseCard(
                  item: item,
                  viewerId: viewerId,
                  viewerIsAdmin: isAdmin,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(itemId: item.id),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── PANEL 4: "Recently returned" ─────────────────────────────────────────
  Widget _buildRecentlyReturnedPanel(
    BuildContext context,
    List<ItemModel> returnedItems,
    String viewerId,
    bool isAdmin,
  ) {
    if (returnedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return SectionPanel(
      title: 'Recently returned',
      subtitle: 'Reunited campus items',
      icon: Icons.celebration_rounded,
      child: Column(
        children: returnedItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CaseCard(
              item: item,
              viewerId: viewerId,
              viewerIsAdmin: isAdmin,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(itemId: item.id),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskBigButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isActionPrimary;
  final VoidCallback onTap;

  const _TaskBigButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.isActionPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActionPrimary
                ? (isDark ? AppColors.coral : AppColors.coralInk)
                : borderColor,
            width: isActionPrimary ? 2.0 : 1.5,
          ),
          boxShadow: isActionPrimary
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.coral : AppColors.coralInk)
                        .withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: badgeColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                color: context.palette.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final p = context.palette;

    final bg = isSelected
        ? (isDark ? AppColors.emerald : AppColors.emeraldInk)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final fg = isSelected
        ? (isDark ? AppColors.onEmerald : Colors.white)
        : p.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : p.hairline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
