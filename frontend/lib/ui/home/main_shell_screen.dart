// lib/ui/home/main_shell_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/accent_pill.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../activity/my_activity_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import 'browse_feed_screen.dart';
import '../../core/widgets/app_backdrop.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _DockEntry {
  final IconData icon;
  final String label;
  final int badge;
  const _DockEntry(this.icon, this.label, {this.badge = 0});
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  String? _lastRole;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminProv = context.watch<AdminProvider>();
    final currentRole = auth.currentUser?.role ?? 'student';
    final isAdmin = auth.currentUser?.isAdmin == true;

    // Reset tab index on role transition (e.g. logging in/out or switching demo account)
    if (_lastRole != null && _lastRole != currentRole) {
      _currentIndex = 0;
    }
    _lastRole = currentRole;

    final List<Widget> screens = isAdmin
        ? const [
            AdminDashboardScreen(
              key: ValueKey('admin_review_screen'),
              isEmbedded: true,
            ),
            BrowseFeedScreen(key: ValueKey('admin_browse_screen')),
            ProfileScreen(key: ValueKey('admin_profile_screen')),
          ]
        : const [
            BrowseFeedScreen(key: ValueKey('student_browse_screen')),
            MyActivityScreen(key: ValueKey('student_activity_screen')),
            ProfileScreen(key: ValueKey('student_profile_screen')),
          ];

    final int totalPendingAdmin =
        adminProv.pendingPosts.length + adminProv.pendingClaims.length;

    final entries = isAdmin
        ? [
            _DockEntry(CupertinoIcons.checkmark_shield_fill, 'Review',
                badge: totalPendingAdmin),
            const _DockEntry(CupertinoIcons.compass, 'Browse'),
            const _DockEntry(CupertinoIcons.person_crop_circle, 'Profile'),
          ]
        : const [
            _DockEntry(CupertinoIcons.compass, 'Browse'),
            _DockEntry(CupertinoIcons.arrow_2_squarepath, 'Activity'),
            _DockEntry(CupertinoIcons.person_crop_circle, 'Profile'),
          ];

    final selected = _currentIndex.clamp(0, screens.length - 1);

    return AppBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: selected, children: screens),
      bottomNavigationBar: _Dock(
        entries: entries,
        selected: selected,
        onSelect: (i) => setState(() => _currentIndex = i),
      ),
    ),
    );
  }
}

/// Floating dock: the active destination expands into a lemon halftone pill,
/// the others collapse to round buttons.
class _Dock extends StatelessWidget {
  final List<_DockEntry> entries;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Dock({
    required this.entries,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _DockItem(
                  entry: entries[i],
                  isSelected: i == selected,
                  onTap: () => onSelect(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final _DockEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      selected: isSelected,
      label: entry.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: isSelected ? 148 : 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : p.circleFill,
                borderRadius: BorderRadius.circular(28),
                border: isSelected ? null : Border.all(color: p.hairline),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.28)
                        : p.shadow,
                    blurRadius: isSelected ? 22 : 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: _duration,
                        opacity: isSelected ? 1 : 0,
                        child: CustomPaint(
                          painter: HalftonePainter(
                            color: AppColors.onAccent.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: OverflowBox(
                      maxWidth: 160,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.icon,
                            size: 22,
                            color: isSelected ? AppColors.onAccent : p.text,
                          ),
                          // The label takes up space only while selected, so
                          // collapsed circles centre the icon on its own.
                          AnimatedSize(
                            duration: _duration,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.centerLeft,
                            child: isSelected
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      entry.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: AppColors.onAccent,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (entry.badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.bg, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.badge > 99 ? '99+' : '${entry.badge}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
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
