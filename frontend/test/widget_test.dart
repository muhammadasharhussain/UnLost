// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:student_app/core/theme/theme_provider.dart';
import 'package:student_app/data/repositories/app_repository.dart';
import 'package:student_app/data/repositories/mock_app_repository.dart';
import 'package:student_app/main.dart';
import 'package:student_app/providers/admin_provider.dart';
import 'package:student_app/providers/auth_provider.dart';
import 'package:student_app/providers/chat_provider.dart';
import 'package:student_app/providers/claims_provider.dart';
import 'package:student_app/providers/items_provider.dart';

void main() {
  testWidgets('UnlostApp smoke test', (WidgetTester tester) async {
    final mockRepo = MockAppRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppRepository>.value(value: mockRepo),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(mockRepo),
          ),
          ChangeNotifierProvider<ItemsProvider>(
            create: (_) => ItemsProvider(mockRepo),
          ),
          ChangeNotifierProvider<ClaimsProvider>(
            create: (_) => ClaimsProvider(mockRepo),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(mockRepo),
          ),
          ChangeNotifierProvider<AdminProvider>(
            create: (_) => AdminProvider(mockRepo),
          ),
        ],
        child: const UnlostApp(),
      ),
    );

    expect(find.byType(UnlostApp), findsOneWidget);

    // Settle splash screen transition
    await tester.pumpAndSettle();

    expect(find.byType(UnlostApp), findsOneWidget);
  });
}
