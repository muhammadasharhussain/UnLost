// lib/ui/profile/profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_panel.dart';
import '../../core/widgets/trust_strip.dart';
import '../../features/reviews/reviews_widgets.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'help_and_about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CustomButton(
            text: 'Sign In',
            variant: ButtonVariant.primary,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 90),
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),

            // 1. Compact Identity Panel
            SectionPanel(
              title: 'Account Identity',
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.hairline, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 13, color: p.textDim),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (user.isAdmin ? AppColors.coral : AppColors.emerald)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.isAdmin ? 'CAMPUS ADMIN' : 'STUDENT',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: user.isAdmin
                                  ? (isDark ? AppColors.coral : AppColors.coralInk)
                                  : (isDark ? AppColors.emerald : AppColors.emeraldInk),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Trust & Feedback Summary Panel
            SectionPanel(
              title: 'Trust & Reputation',
              subtitle: 'Based on verified returns and community reviews',
              icon: CupertinoIcons.shield_lefthalf_fill,
              child: Column(
                children: [
                  TrustStrip(score: user.trustScore),
                  const SizedBox(height: 12),
                  UserReviewsSection(userId: user.id),
                ],
              ),
            ),

            // 3. Theme Toggle Panel
            SectionPanel(
              title: 'Appearance',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                  color: isDark ? AppColors.champagne : AppColors.champagneInk,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  isDark ? 'Emerald Ink Dark Theme' : 'Champagne Light Theme',
                  style: TextStyle(fontSize: 12, color: p.textDim),
                ),
                value: isDark,
                onChanged: (val) {
                  context.read<ThemeProvider>().setThemeMode(
                        val ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ),

            // 4. ONE "Help & about" Row (Progressive disclosure: opens dedicated screen)
            SectionPanel(
              title: 'Support & Extras',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  CupertinoIcons.question_circle_fill,
                  color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                ),
                title: const Text(
                  'Help & About',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('FAQs, credits, demo accounts'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpAndAboutScreen()),
                  );
                },
              ),
            ),

            // 5. Sign Out
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CustomButton(
                text: 'Sign Out',
                variant: ButtonVariant.outline,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
