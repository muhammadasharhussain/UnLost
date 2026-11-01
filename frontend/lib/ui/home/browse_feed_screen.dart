import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/beam_search_bar.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/hover_color_icon.dart';
import '../../core/widgets/unlost_wordmark.dart';
import '../../features/help/coach_tour.dart';
import '../../features/help/help_bot_engine.dart';
import '../../features/help/help_bot_sheet.dart';
import '../../features/help/help_nudge.dart';
import '../../features/reviews/reviews_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/reviews_provider.dart';
import '../items/item_detail_screen.dart';
import '../items/post_found_screen.dart';
import '../items/post_lost_screen.dart';

class BrowseFeedScreen extends StatefulWidget {
  const BrowseFeedScreen({super.key});

  @override
  State<BrowseFeedScreen> createState() => _BrowseFeedScreenState();
}

class _BrowseFeedScreenState extends State<BrowseFeedScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRunTour();
  }

  Future<void> _checkFirstRunTour() async {
    final should = await TourController.shouldShowTour();
    if (should && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final isAdmin = context.read<AuthProvider>().currentUser?.isAdmin == true;
        TourController.start(context, isAdmin: isAdmin);
      });
    }
  }

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
      floatingActionButton: HelpNudge(
        builder: (context, dismissNudge) => _HelpFab(
          key: TourController.helpKey,
          onTap: () {
            dismissNudge();
            HelpBotSheet.show(
              context,
              contextData: HelpContext(
                role: isAdmin ? 'admin' : 'student',
                currentScreen: 'home',
              ),
              onAction: (act) {
                if (act == 'nav_post') {
                  _showPostTypeSelector(context);
                } else if (act == 'start_tour') {
                  TourController.start(context, isAdmin: isAdmin);
                }
              },
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              itemsProv.loadItems(),
              context.read<ReviewsProvider>().loadReunions(),
            ]);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildHero(context, itemsProv)),
              const SliverToBoxAdapter(child: RecentlyReturnedStrip()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        key: TourController.searchKey,
                        child: _SearchField(
                          query: itemsProv.searchQuery,
                          onChanged: itemsProv.onSearchChanged,
                          onClear: itemsProv.clearSearch,
                        ),
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
          const SizedBox(height: 12),
          Text(
            'Lost it. Report it. Get it back.',
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'Unlost reunites students with what they lose on campus. '
              'Every post and claim is checked by an admin, so only the real owner gets it back.',
              style: TextStyle(fontSize: 13, height: 1.45, color: p.textDim),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero: compact 3-stat tiles + full-width Post item button ────────────
  Widget _buildHero(BuildContext context, ItemsProvider prov) {
    final dark = context.isDarkMode;
    final items = prov.items;
    final total = items.length;
    final handover = items.where((i) => i.isHandoverPending).length;
    final open = total - handover;
    final returned = items.where((i) => i.isResolved).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          // Row of 3 stat tiles
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  context,
                  title: 'OPEN CASES',
                  value: '$open',
                  accentColor: dark ? AppColors.emerald : AppColors.emeraldInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  context,
                  title: 'IN HANDOVER',
                  value: '$handover',
                  accentColor: dark ? AppColors.champagne : AppColors.champagneInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  context,
                  title: 'RETURNED',
                  value: '$returned',
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Post item button (Full width, dark-pill look in both light & dark)
          Semantics(
            button: true,
            label: 'Post item',
            child: InkWell(
              onTap: () => _showPostTypeSelector(context),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkCard, // Emerald dark card
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.plus_circle_fill, size: 20, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    const Text(
                      'Post an item',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color accentColor,
  }) {
    final dark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: context.palette.textFaint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
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
                  activeColor: isSelected ? AppColors.onCerulean : AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.onCerulean : p.text,
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
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final int crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 320,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = prov.items[index];
                  final auth = context.read<AuthProvider>();
                  final viewerId = auth.currentUser?.id ?? '';
                  final isAdmin = auth.currentUser?.isAdmin == true;

                  return CaseCard(
                    item: item,
                    viewerId: viewerId,
                    viewerIsAdmin: isAdmin,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
                      );
                    },
                  );
                },
                childCount: prov.items.length,
              ),
            );
          },
        ),
      ),
    ];
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

// ── Floating Help button (opens help chatbot) ─────────────────────────
class _HelpFab extends StatelessWidget {
  final VoidCallback onTap;
  const _HelpFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Help guide',
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: dark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(
            color: dark ? AppColors.emerald : AppColors.emeraldInk,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.question_circle_fill,
                    size: 20,
                    color: dark ? AppColors.emerald : AppColors.emeraldInk,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Help',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      color: context.palette.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
