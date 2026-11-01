// test/help_bot_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/help/help_bot_engine.dart';

void main() {
  group('HelpBotEngine Comprehensive Intent & Context Tests', () {
    late LocalHelpBotEngine bot;
    const defaultCtx = HelpContext(role: 'student', currentScreen: 'home');

    setUp(() {
      bot = LocalHelpBotEngine();
    });

    test('Intent: Out-of-scope messages get polite refusal and suggestion chips', () async {
      final queries = [
        'tell me a joke',
        'what is the weather in Delhi today?',
        'solve my math homework calculus integral',
        'what is the latest politics news?',
        'recipe for chocolate cake',
      ];

      for (final q in queries) {
        final reply = await bot.reply(q, defaultCtx);
        expect(
          reply.text,
          equals("This is not something I can help with. I'm here only to guide you about the UnLost app."),
        );
        expect(reply.quickReplies, containsAll(['Report lost item', 'Report found item', 'Track my case']));
        expect(reply.actions, isEmpty);
      }
    });

    test('Intent: Vague lost message asks for details (item, location, time)', () async {
      final vagueQueries = [
        'I lost an item',
        'mera bag kho gaya',
        'someone took my phone',
        'loost my stuff',
        'gum ho gaya mera saman',
      ];

      for (final q in vagueQueries) {
        bot.resetConversation();
        final reply = await bot.reply(q, defaultCtx);
        expect(reply.text.toLowerCase(), contains('tell me'));
        expect(reply.text.toLowerCase(), contains('what item'));
        expect(reply.quickReplies, isNotEmpty);
      }
    });

    test('Intent: Specific lost message gives direct steps and Report Lost button', () async {
      bot.resetConversation();
      final reply = await bot.reply('Lost my dell laptop in library', defaultCtx);
      expect(reply.text.toLowerCase(), contains('laptop'));
      expect(reply.text.toLowerCase(), contains('library'));
      expect(reply.actions.any((a) => a.actionId == 'nav_post'), isTrue);
    });

    test('Intent: Vague lost followed by details provides steps and button', () async {
      bot.resetConversation();
      // Step 1: Vague message
      final reply1 = await bot.reply('I lost an item', defaultCtx);
      expect(reply1.text.toLowerCase(), contains('tell me'));

      // Step 2: User answers with item and location
      final reply2 = await bot.reply('Black backpack at cafeteria', defaultCtx);
      expect(reply2.text.toLowerCase(), contains('backpack'));
      expect(reply2.text.toLowerCase(), contains('cafeteria'));
      expect(reply2.actions.any((a) => a.actionId == 'nav_post'), isTrue);
    });

    test('Intent: Found item (English + Hinglish)', () async {
      final foundQueries = [
        'I found a set of keys near gym',
        'mujhe library me phone mila',
        'picked up an umbrella',
      ];

      for (final q in foundQueries) {
        bot.resetConversation();
        final reply = await bot.reply(q, defaultCtx);
        expect(reply.text.toLowerCase(), contains('found'));
        expect(reply.actions.any((a) => a.actionId == 'nav_post'), isTrue);
      }
    });

    test('Intent: Claim process explanation', () async {
      final claimQueries = [
        'how do claims work?',
        'this is mine',
        'how to claim my lost item',
        'verify answers',
      ];

      for (final q in claimQueries) {
        bot.resetConversation();
        final reply = await bot.reply(q, defaultCtx);
        expect(reply.text.toLowerCase(), contains('private verification questions'));
        expect(reply.actions.any((a) => a.actionId == 'nav_browse'), isTrue);
      }
    });

    test('Intent: Status and progress tracking', () async {
      final statusQueries = [
        'track my case',
        'what is the status of my report',
        'is it under review?',
        'kahan tak pahuncha mera case',
      ];

      for (final q in statusQueries) {
        bot.resetConversation();
        final reply = await bot.reply(q, defaultCtx);
        expect(reply.text.toLowerCase(), contains('my activity'));
        expect(reply.actions.any((a) => a.actionId == 'nav_activity'), isTrue);
      }
    });

    test('Intent: Reviews and Trust Score explanation', () async {
      final reviewQueries = [
        'how do reviews work?',
        'what is trust score?',
        'how to give feedback and stars',
      ];

      for (final q in reviewQueries) {
        bot.resetConversation();
        final reply = await bot.reply(q, defaultCtx);
        expect(reply.text.toLowerCase(), contains('trust score'));
        expect(reply.text.toLowerCase(), contains('review'));
      }
    });

    test('Contextual memory: Follow-up question uses remembered context', () async {
      bot.resetConversation();
      // First turn: User states they lost their iphone
      await bot.reply('I lost my iphone in the library', defaultCtx);

      // Second turn: User asks "what should I do next?"
      final followUp = await bot.reply('what should I do next?', defaultCtx);
      expect(followUp.text.toLowerCase(), contains('iphone'));
      expect(followUp.actions.any((a) => a.actionId == 'nav_post'), isTrue);
    });
  });
}
