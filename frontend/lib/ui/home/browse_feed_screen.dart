// lib/ui/home/browse_feed_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/beam_search_bar.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/dot_matrix_text.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glow_pill_button.dart';
import '../../core/widgets/unlost_wordmark.dart';
import '../../core/widgets/hover_color_icon.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/tick_ring_gauge.dart';
import '../../data/models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../items/item_detail_screen.dart';
import '../items/post_found_screen.dart';
import '../items/post_lost_screen.dart';

class BrowseFeedScreen extends StatelessWidget {
  const BrowseFeedScreen({super.key});

  // ── Post sheet ───────────────────────────────────────────────────────────
  void _showPostTypeSelector(BuildContext context) {
    final p = context.palette;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Post to campus feed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Did you find something, or lose it?',
                  style: TextStyle(fontSize: 14, color: p.textDim),
                ),
                const SizedBox(height: 20),
                _postOption(
                  context,
                  icon: CupertinoIcons.checkmark_shield_fill,
                  color: AppColors.success,
                  bg: AppColors.successBg,
                  title: 'I found something',
                  subtitle: 'Post it with 2 private verification questions',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PostFoundScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _postOption(
                  context,
                  icon: CupertinoIcons.search_circle_fill,
                  color: AppColors.warning,
                  bg: AppColors.warningBg,
                  title: 'I lost something',
                  subtitle: 'Report it so the community can help look',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PostLostScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _postOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: p.textDim)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 16, color: p.textFaint),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final itemsProv = context.watch<ItemsProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.isAdmin == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          isAdmin ? null : _PostFab(onTap: () => _showPostTypeSelector(context)),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => itemsProv.loadItems(),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildHero(context, itemsProv)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      _SearchField(
                        query: itemsProv.searchQuery,
                        onChanged: itemsProv.onSearchChanged,
                        onClear: itemsProv.clearSearch,
                      ),
                      const SizedBox(height: 12),
                      _buildSegmented(context, itemsProv),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategoryChips(context, itemsProv)),
              ..._buildFeedSlivers(context, itemsProv, p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const UnlostWordmark(),
              const Spacer(),
              CircleIconButton(
                icon: isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                tooltip:
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                onTap: () => context
                    .read<ThemeProvider>()
                    .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'Unlost reunites students with what they lose on campus. '
              'Every post and claim is checked by an admin, so only the real owner gets it back.',
              style: TextStyle(fontSize: 13.5, height: 1.45, color: p.textDim),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero: tick-ring gauge ────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, ItemsProvider prov) {
    final p = context.palette;
    final items = prov.items;
    final total = items.length;
    final handover = items.where((i) => i.isHandoverPending).length;
    final open = total - handover;
    final loading = prov.isLoading && items.isEmpty;
    final value = total == 0 ? 0.0 : handover / total;
    final isFound = prov.activeType == 'found';

    final digits = loading ? 2 : '$total'.length;
    final dot = digits <= 2 ? 6.5 : (digits == 3 ? 5.0 : 3.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        radius: 36,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Campus board',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: p.text,
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()),
                  style: TextStyle(fontSize: 12, color: p.textFaint),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth < 236 ? constraints.maxWidth : 236.0;
                return TickRingGauge(
                  size: size,
                  value: value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DotMatrixText(
                        loading ? '--' : '$total',
                        dotSize: dot,
                        gap: dot * 0.37,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFound ? 'found items listed' : 'lost reports listed',
                        style: TextStyle(fontSize: 13, color: p.textDim),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(p.tickActive, '$open open', p),
                const SizedBox(width: 22),
                _legendDot(AppColors.accent, '$handover in handover', p),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label, UnlostPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textDim)),
      ],
    );
  }

  // ── Found / Lost segmented control ───────────────────────────────────────
  Widget _buildSegmented(BuildContext context, ItemsProvider prov) {
    final p = context.palette;
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
          Expanded(
            child: _segment(
              context,
              label: 'Found items',
              dot: AppColors.success,
              isSelected: prov.activeType == 'found',
              onTap: () => prov.setActiveType('found'),
            ),
          ),
          Expanded(
            child: _segment(
              context,
              label: 'Lost reports',
              dot: AppColors.warning,
              isSelected: prov.activeType == 'lost',
              onTap: () => prov.setActiveType('lost'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required Color dot,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? p.invertedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: isSelected ? p.invertedText : p.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────────────────────
  Widget _buildCategoryChips(BuildContext context, ItemsProvider prov) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _chip(
              context,
              name: 'All categories',
              icon: CupertinoIcons.square_grid_2x2,
              isSelected: prov.activeCategory == 'all',
              onTap: () => prov.setActiveCategory('all'),
            ),
            ...ItemCategories.all.map((cat) {
              return _chip(
                context,
                name: cat.name,
                icon: cat.icon,
                isSelected: prov.activeCategory == cat.id,
                onTap: () => prov.setActiveCategory(cat.id),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: name,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : p.circleFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? AppColors.primary : p.hairline,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverColorIcon(
                  icon: icon,
                  size: 16,
                  isSelected: isSelected,
                  activeColor: isSelected ? Colors.white : AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : p.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Feed ─────────────────────────────────────────────────────────────────
  List<Widget> _buildFeedSlivers(
    BuildContext context,
    ItemsProvider prov,
    UnlostPalette p,
  ) {
    if (prov.isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      ];
    }

    if (prov.errorMessage != null) {
      return [
        SliverToBoxAdapter(
          child: ErrorStateView(
            title: 'Unable to load feed',
            message: prov.errorMessage!,
            onRetry: () => prov.loadItems(),
          ),
        ),
      ];
    }

    if (prov.items.isEmpty) {
      final isSearch = prov.searchQuery.isNotEmpty;
      return [
        SliverToBoxAdapter(
          child: EmptyStateView(
            icon: isSearch ? CupertinoIcons.search : CupertinoIcons.tray,
            title: isSearch ? 'No results found' : 'Nothing in this category',
            message: isSearch
                ? 'No approved items matched "${prov.searchQuery}". Try different words or clear the search.'
                : 'Be the first to post a verified ${prov.activeType} item on campus.',
            actionLabel: isSearch ? 'Clear search' : 'Post an item',
            onAction: () {
              if (isSearch) {
                prov.clearSearch();
              } else {
                _showPostTypeSelector(context);
              }
            },
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        sliver: SliverList.separated(
          itemCount: prov.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) =>
              _buildItemCard(context, prov.items[index]),
        ),
      ),
    ];
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    final p = context.palette;
    final cat = ItemCategories.getById(item.category);
    final dateStr = DateFormat('MMM d, h:mm a').format(item.dateTime);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
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
                  color: p.isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                ),
                child: HoverColorIcon(
                  icon: cat.icon,
                  size: 20,
                  activeColor: item.isFound ? AppColors.success : AppColors.warning,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: p.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(dateStr, style: TextStyle(fontSize: 11.5, color: p.textFaint)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: item.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: p.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: p.textDim, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, size: 14, color: p.textFaint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.textDim,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Footer: poster trust (dial) on the left, main action on the right.
          Row(
            children: [
              TickRingGauge(
                size: 56,
                tickCount: 40,
                value: item.posterTrustScore / 100.0,
                showMarker: false,
                duration: const Duration(milliseconds: 600),
                child: DotMatrixText(
                  '${item.posterTrustScore}',
                  dotSize: 1.6,
                  gap: 0.7,
                  color: p.text,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.posterTrustLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.textDim, height: 1.3),
                ),
              ),
              const SizedBox(width: 10),
              GlowPillButton(
                label: item.isFound ? 'Claim item' : 'I found this',
                height: 44,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(itemId: item.id)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Search field (keeps text in sync with the provider) ────────────────────
class _SearchField extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BeamSearchBar(
      controller: _controller,
      onChanged: widget.onChanged,
      onClear: widget.onClear,
      hint: 'Search',
    );
  }
}

// ── Floating "Post item" action: flat lemon pill ──────────────────────
class _PostFab extends StatelessWidget {
  final VoidCallback onTap;
  const _PostFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Post item',
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppColors.accent,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.plus, size: 20, color: AppColors.onAccent),
                  SizedBox(width: 8),
                  Text(
                    'Post item',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
