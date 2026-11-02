// lib/ui/profile/help_and_about_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_backdrop.dart';
import '../../core/widgets/section_panel.dart';
import '../../providers/auth_provider.dart';
import 'about_credits_screen.dart';
import 'faqs_screen.dart';

class HelpAndAboutScreen extends StatelessWidget {
  const HelpAndAboutScreen({super.key});

  void _showDemoSwitchDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final p = context.palette;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          child: SingleChildScrollView(
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
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch between student trust tiers and campus admin roles.',
                  style: TextStyle(fontSize: 13, color: p.textDim),
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
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? AppColors.emerald : AppColors.emeraldInk,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.shield_fill,
                      color: context.isDarkMode ? AppColors.onEmerald : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text('Campus Administrator'),
                  subtitle: const Text('admin@campus.edu • Full approval queue'),
                  onTap: () {
                    auth.switchAccount('admin@campus.edu');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Help & About'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: p.text, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // FAQ & Guide
              SectionPanel(
                title: 'Guides & Support',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        CupertinoIcons.question_circle_fill,
                        color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                      ),
                      title: const Text('Frequently Asked Questions'),
                      subtitle: const Text('How verification and handovers work'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        CupertinoIcons.info_circle_fill,
                        color: isDark ? AppColors.champagne : AppColors.champagneInk,
                      ),
                      title: const Text('About UnLost & Credits'),
                      subtitle: const Text('Version, licenses and community'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutCreditsScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              // Developer & Demo Options
              SectionPanel(
                title: 'Demo & Testing Options',
                subtitle: 'Switch accounts to test admin queues and trust levels',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    CupertinoIcons.person_2_fill,
                    color: isDark ? AppColors.coral : AppColors.coralInk,
                  ),
                  title: const Text('Switch Demo Account'),
                  subtitle: const Text('Simulate admin, high-trust or new student'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showDemoSwitchDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
