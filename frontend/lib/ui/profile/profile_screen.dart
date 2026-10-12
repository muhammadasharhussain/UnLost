// lib/ui/profile/profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/dot_matrix_text.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/tick_ring_gauge.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'about_credits_screen.dart';
import 'faqs_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDemoSwitchDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final p = context.palette;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              const SizedBox(height: 20),
              Text(
                'Switch demo account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.6,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'See Unlost from different student trust tiers, or as campus admin.',
                style: TextStyle(fontSize: 13, color: p.textDim, height: 1.4),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(child: Text('T')),
                title: const Text('Terry Melton (Student, high trust)'),
                subtitle: const Text('terry@campus.edu • Trust 88'),
                onTap: () {
                  auth.switchAccount('terry@campus.edu');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Text('S')),
                title: const Text('Sarah Jenkins (Student, mid trust)'),
                subtitle: const Text('sarah@campus.edu • Trust 64'),
                onTap: () {
                  auth.switchAccount('sarah@campus.edu');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Text('A')),
                title: const Text('Alex Chen (Student, new account)'),
                subtitle: const Text('alex@campus.edu • Trust 38'),
                onTap: () {
                  auth.switchAccount('alex@campus.edu');
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.shield_fill,
                      color: AppColors.onAccent, size: 20),
                ),
                title: const Text('Dean Reynolds (Admin)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('admin@campus.edu • Role: admin'),
                onTap: () {
                  auth.switchAccount('admin@campus.edu');
                  Navigator.pop(ctx);
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
    final auth = context.watch<AuthProvider>();
    final repo = context.watch<AppRepository>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: CustomButton(
              text: 'Log in',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                    color: p.text,
                  ),
                ),
              ),

              // ── Identity ──
              GlassCard(
                radius: 32,
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.violetA, AppColors.violetB],
                        ),
                      ),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    color: p.text,
                                  ),
                                ),
                              ),
                              if (user.isAdmin) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: p.textDim),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.phone,
                            style: TextStyle(fontSize: 12.5, color: p.textFaint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Student only: trust gauge + stats ──
              if (!user.isAdmin) ...[
                _buildTrustCard(context, user.trustScore, user.trustLabel),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        tone: CardTone.violet,
                        label: 'Items returned',
                        value: user.itemsReturned,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _statCard(
                        context,
                        tone: CardTone.indigo,
                        label: 'Items recovered',
                        value: user.itemsRecovered,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 12),

              // ── Appearance ──
              _sectionTitle(context, 'Appearance'),
              const _ThemeSelector(),
              const SizedBox(height: 28),

              // ── Information ──
              _sectionTitle(context, 'Preferences & information'),
              GlassCard(
                radius: 28,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(CupertinoIcons.question_circle_fill, size: 21),
                      title: const Text('Frequently asked questions',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                      trailing: Icon(CupertinoIcons.chevron_right,
                          size: 15, color: p.textFaint),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FaqsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: p.hairline),
                    ListTile(
                      leading: const Icon(CupertinoIcons.info_circle_fill, size: 21),
                      title: const Text('About Unlost & credits',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                      trailing: Icon(CupertinoIcons.chevron_right,
                          size: 15, color: p.textFaint),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutCreditsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Developer / demo controls ──
              _sectionTitle(context, 'Developer & demo controls'),
              GlassCard(
                radius: 28,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: repo.simulateErrors,
                      onChanged: (val) {
                        repo.simulateErrors = val;
                        (context as Element).markNeedsBuild();
                      },
                      title: const Text('Simulate network errors',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                      subtitle: const Text(
                          'Force failures to test error states and retry',
                          style: TextStyle(fontSize: 12)),
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: p.hairline),
                    ListTile(
                      leading: const Icon(CupertinoIcons.person_2_fill, size: 21),
                      title: const Text('Switch demo account',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Move between students or the admin account',
                          style: TextStyle(fontSize: 12)),
                      trailing: Icon(CupertinoIcons.chevron_right,
                          size: 15, color: p.textFaint),
                      onTap: () => _showDemoSwitchDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Log out',
                icon: CupertinoIcons.arrow_right_square,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                variant: ButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          color: p.textDim,
        ),
      ),
    );
  }

  Widget _buildTrustCard(BuildContext context, int score, String label) {
    final p = context.palette;
    return GlassCard(
      radius: 36,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community trust',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: p.text,
                ),
              ),
              Text(label, style: TextStyle(fontSize: 12.5, color: p.textDim)),
            ],
          ),
          const SizedBox(height: 18),
          TickRingGauge(
            size: 200,
            value: score / 100.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DotMatrixText(
                  '$score',
                  dotSize: score >= 100 ? 4.6 : 6,
                  gap: score >= 100 ? 1.7 : 2.2,
                ),
                const SizedBox(height: 12),
                Text('out of 100', style: TextStyle(fontSize: 13, color: p.textDim)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Returning found items adds 6 points and confirming a recovery adds 4. A fraudulent claim removes 15, and three fake reports suspend the account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textDim, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required CardTone tone,
    required String label,
    required int value,
  }) {
    final dim = GlassCard.foregroundDim(context, tone);
    final fg = GlassCard.foreground(context, tone);
    return GlassCard(
      tone: tone,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: dim),
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DotMatrixText('$value', dotSize: 5, gap: 1.9, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-way System / Light / Dark switch.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = context.watch<ThemeProvider>();

    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, 'System', CupertinoIcons.circle_lefthalf_fill),
      (ThemeMode.light, 'Light', CupertinoIcons.sun_max),
      (ThemeMode.dark, 'Dark', CupertinoIcons.moon),
    ];

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
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: themeProv.themeMode == o.$1,
                label: '${o.$2} theme',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => themeProv.setThemeMode(o.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: themeProv.themeMode == o.$1
                          ? p.invertedFill
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          o.$3,
                          size: 16,
                          color: themeProv.themeMode == o.$1
                              ? p.invertedText
                              : p.textDim,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: themeProv.themeMode == o.$1
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: themeProv.themeMode == o.$1
                                ? p.invertedText
                                : p.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
