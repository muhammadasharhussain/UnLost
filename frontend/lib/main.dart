// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/mock_app_repository.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/claims_provider.dart';
import 'providers/items_provider.dart';
import 'ui/auth/splash_gate_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate the mock data repository holding the in-memory seed dataset.
  // In the future, this is the single seam where HttpAppRepository will be plugged in.
  final appRepository = MockAppRepository();

  runApp(
    MultiProvider(
      providers: [
        // App Repository Contract (Data layer)
        Provider<AppRepository>.value(value: appRepository),

        // Global Theme State
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        // Core Domain Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(appRepository),
        ),
        ChangeNotifierProvider<ItemsProvider>(
          create: (_) => ItemsProvider(appRepository),
        ),
        ChangeNotifierProvider<ClaimsProvider>(
          create: (_) => ClaimsProvider(appRepository),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(appRepository),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(appRepository),
        ),
      ],
      child: const UnlostApp(),
    ),
  );
}

class UnlostApp extends StatelessWidget {
  const UnlostApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Unlost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const SplashGateScreen(),
    );
  }
}
