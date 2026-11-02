// lib/ui/home/main_shell_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_backdrop.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../activity/my_activity_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../items/post_found_screen.dart';
import '../items/post_lost_screen.dart';
import '../profile/profile_screen.dart';
import '../reviews/reviews_screen.dart';
import 'browse_feed_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  String? _lastRole;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _showPostChooser(BuildContext context) {
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
                'Create a Report',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Report what was lost or found on campus',
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
    final auth = context.watch<AuthProvider>();
    final adminProv = context.watch<AdminProvider>();
    final claimsProv = context.watch<ClaimsProvider>();
    final currentRole = auth.currentUser?.role ?? 'student';
    final isAdmin = auth.currentUser?.isAdmin == true;

    if (_lastRole != null && _lastRole != currentRole) {
      _currentIndex = 0;
    }
    _lastRole = currentRole;

    // Admin layout: Home | Admin | Reviews | Profile  (4 tabs + centre FAB)
    // Student layout: Home | Activity | Reviews | Profile (4 tabs + centre FAB)
    final List<Widget> screens = isAdmin
        ? const [
            BrowseFeedScreen(key: ValueKey('admin_browse_screen')),
            AdminDashboardScreen(
              key: ValueKey('admin_review_screen'),
              isEmbedded: true,
            ),
            ReviewsScreen(key: ValueKey('admin_reviews_screen')),
            ProfileScreen(key: ValueKey('admin_profile_screen')),
          ]
        : const [
            BrowseFeedScreen(key: ValueKey('student_browse_screen')),
            MyActivityScreen(key: ValueKey('student_activity_screen')),
            ReviewsScreen(key: ValueKey('student_reviews_screen')),
            ProfileScreen(key: ValueKey('student_profile_screen')),
          ];

    final totalBadge = isAdmin
        ? (adminProv.pendingPosts.length + adminProv.pendingClaims.length)
        : claimsProv.totalFinderClaimsAwaitingOwner;

    final selected = _currentIndex.clamp(0, screens.length - 1);

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: selected, children: screens),
        bottomNavigationBar: _BottomDock(
          selectedIndex: selected,
          activityBadge: totalBadge,
          activityLabel: isAdmin ? 'Admin' : 'Activity',
          onSelect: (i) => setState(() => _currentIndex = i),
          onPostTap: () => _showPostChooser(context),
        ),
      ),
    );
  }
}

/// Task-first Bottom Dock
///   [Home]  [Activity/Admin]  [+]  [Reviews]  [Profile]
///     0          1           FAB      2           3
class _BottomDock extends StatelessWidget {
  final int selectedIndex;
  final int activityBadge;
  final String activityLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onPostTap;

  const _BottomDock({
    required this.selectedIndex,
    required this.activityBadge,
    required this.activityLabel,
    required this.onSelect,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      decoration: BoxDecoration(
        color: p.panel.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: p.panelBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left 1: Home
            _DockItem(
              icon: CupertinoIcons.compass,
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            // Left 2: Activity / Admin
            _DockItem(
              icon: CupertinoIcons.arrow_2_squarepath,
              label: activityLabel,
              badge: activityBadge,
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            // Centre FAB: + Post
            GestureDetector(
              onTap: onPostTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.emerald : AppColors.emeraldInk)
                          .withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                ),
              ),
            ),
            // Right 1: Reviews
            _DockItem(
              icon: CupertinoIcons.star_fill,
              label: 'Reviews',
              isSelected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            // Right 2: Profile
            _DockItem(
              icon: CupertinoIcons.person_crop_circle,
              label: 'Profile',
              isSelected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final p = context.palette;

    final activeColor = isDark ? AppColors.emerald : AppColors.emeraldInk;
    final color = isSelected ? activeColor : p.textDim;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.coral : AppColors.coralInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.onCoral : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
