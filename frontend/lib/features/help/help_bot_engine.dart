// lib/features/help/help_bot_engine.dart
import 'dart:async';
import '../../core/matching/match_scorer.dart';

class BotAction {
  final String label;
  final String actionId;

  const BotAction({required this.label, required this.actionId});
}

class BotReply {
  final String text;
  final List<String> quickReplies;
  final List<BotAction> actions;

  const BotReply({
    required this.text,
    this.quickReplies = const [],
    this.actions = const [],
  });
}

class HelpContext {
  final String role; // 'student' | 'admin'
  final String currentScreen; // 'home' | 'my_activity' | 'profile' | 'admin_queue'

  const HelpContext({
    required this.role,
    required this.currentScreen,
  });
}

abstract class HelpBotEngine {
  Future<BotReply> reply(String text, HelpContext ctx);
  void resetConversation();
}

/// Tracks conversational state across multiple turns for context retention.
class BotConversationState {
  String? rememberedItem;
  String? rememberedLocation;
  String? lastIntent; // 'lost' | 'found' | 'claim' | 'status' | 'out_of_scope'
  int vagueFollowupStage = 0; // 0 = none, 1 = awaiting details

  void reset() {
    rememberedItem = null;
    rememberedLocation = null;
    lastIntent = null;
    vagueFollowupStage = 0;
  }
}

class LocalHelpBotEngine implements HelpBotEngine {
  final BotConversationState _state = BotConversationState();

  @override
  void resetConversation() {
    _state.reset();
  }

  static const List<String> defaultQuickReplies = [
    'Report lost item',
    'Report found item',
    'Track my case',
  ];

  static const List<String> standardQuickReplies = [
    'Show me around',
    'Report lost item',
    'Report found item',
    'Track my case',
    'How do claims work?',
    'What is the handover code?',
  ];

  // Common campus locations for entity extraction
  static const List<String> _campusLocations = [
    'library',
    'cafeteria',
    'canteen',
    'student center',
    'gym',
    'lab',
    'auditorium',
    'hostel',
    'dorm',
    'parking',
    'sports complex',
    'hall',
    'classroom',
    'gate',
    'ground',
  ];

  // Common item nouns for entity extraction (more specific first)
  static const List<String> _commonItems = [
    'water bottle',
    'student card',
    'headphones',
    'keychain',
    'backpack',
    'earbuds',
    'airpods',
    'macbook',
    'umbrella',
    'glasses',
    'charger',
    'iphone',
    'samsung',
    'laptop',
    'wallet',
    'jacket',
    'mobile',
    'bottle',
    'phone',
    'purse',
    'watch',
    'keys',
    'card',
    'dell',
    'bag',
    'id',
  ];

  @override
  Future<BotReply> reply(String text, HelpContext ctx) async {
    // Natural thinking delay
    await Future.delayed(const Duration(milliseconds: 350));

    final raw = text.trim();
    if (raw.isEmpty) {
      return const BotReply(
        text: 'Hello! I am your Unlost campus guide. How can I assist you with lost or found items today?',
        quickReplies: defaultQuickReplies,
      );
    }

    final lower = raw.toLowerCase();
    final tokens = MatchScorer.tokenizeAndNormalize(lower).toSet();

    // ── 1. Out-of-Scope Detection ──────────────────────────────────────────
    // Jokes, homework, news, coding questions, general chit-chat unrelated to lost & found
    if (_isOutOfScope(lower, tokens)) {
      _state.lastIntent = 'out_of_scope';
      return const BotReply(
        text: 'This is not something I can help with. I\'m here only to guide you about the UnLost app.',
        quickReplies: [
          'Report lost item',
          'Report found item',
          'Track my case',
        ],
      );
    }

    // ── 2. Tour Request ────────────────────────────────────────────────────
    if (lower.contains('show me around') || lower == 'tour' || lower.contains('walkthrough')) {
      _state.lastIntent = 'tour';
      return const BotReply(
        text: 'Welcome to Unlost! Here is how the campus app works:\n'
            '• Browse: View active lost & found cases on campus\n'
            '• Post item: Report what you lost or found\n'
            '• My Activity: Track your case status & view 6-digit pickup codes\n'
            '• How it works: 7 verification stages ensure genuine owner returns.',
        actions: [BotAction(label: 'Start interactive tour', actionId: 'start_tour')],
        quickReplies: defaultQuickReplies,
      );
    }

    // ── 3. Extract items & locations if mentioned in message ───────────────
    for (final loc in _campusLocations) {
      if (lower.contains(loc)) {
        _state.rememberedLocation = loc;
        break;
      }
    }
    for (final it in _commonItems) {
      if (lower.contains(it)) {
        _state.rememberedItem = it;
        break;
      }
    }

    // ── 4. Follow-up Context Resolution ────────────────────────────────────
    // If user asks "what should I do next?", "what's its status?", "kya karu abhi?"
    final isFollowUp = _isFollowUpQuestion(lower, tokens);
    if (isFollowUp && _state.lastIntent != null) {
      return _handleFollowUp(ctx);
    }

    // ── 5. If answering vague reporting prompt (stage 1) ───────────────────
    if (_state.vagueFollowupStage == 1 && (_state.lastIntent == 'lost' || _state.lastIntent == 'found')) {
      _state.vagueFollowupStage = 0;
      final isLost = _state.lastIntent == 'lost';
      final itemDesc = _state.rememberedItem ?? 'item';
      final locDesc = _state.rememberedLocation != null ? ' near the ${_state.rememberedLocation}' : '';

      return BotReply(
        text: 'Thank you for providing the details! I have noted your $itemDesc$locDesc.\n\n'
            'Here are your next steps:\n'
            '1. Tap the button below to open the ${isLost ? "Post Lost" : "Post Found"} report screen.\n'
            '2. Provide photos and 2 private verification questions.\n'
            '3. Campus admin will verify and publish your report immediately.',
        actions: [
          BotAction(
            label: isLost ? 'Report Lost Item' : 'Report Found Item',
            actionId: 'nav_post',
          ),
        ],
        quickReplies: ['Track my case', 'How do claims work?'],
      );
    }

    // ── 6. Claim Intent Detection (Checked before lost intent) ────────────
    // e.g. "how do claims work", "this is mine", "how to claim my lost item", "verify answers"
    if (_isClaimIntent(lower, tokens)) {
      _state.lastIntent = 'claim';
      return const BotReply(
        text: 'When you spot your lost item on the feed, tap "This is mine":\n\n'
            '1. Answer the finder\'s private verification questions.\n'
            '2. Admin checks your answers against stored details to prevent fake claims.\n'
            '3. Once approved, coordinate safe handover with the finder in a public campus zone.',
        actions: [
          BotAction(label: 'Browse Campus Feed', actionId: 'nav_browse'),
        ],
        quickReplies: ['What is the handover code?', 'Track my case'],
      );
    }

    // ── 7. Lost Intent Detection (English + Hinglish + Typos) ───────────────
    // e.g. "I lost an item", "mera bag kho gaya", "someone took my phone", "lost wallet"
    if (_isLostIntent(lower, tokens)) {
      _state.lastIntent = 'lost';

      // If message is vague (missing location/time, or generic statement like "i lost an item", "mera bag kho gaya", "someone took my phone")
      final hasLocation = _state.rememberedLocation != null;
      final isGenericPrompt = lower.contains('an item') ||
          lower.contains('something') ||
          lower.contains('mera bag kho gaya') ||
          lower.contains('someone took my') ||
          lower.contains('gum ho gaya') ||
          lower.contains('lost keys today') ||
          (!hasLocation && !lower.contains('yesterday') && !lower.contains('morning') && !lower.contains('today'));

      if (isGenericPrompt || (!hasLocation && _state.rememberedItem == null)) {
        _state.vagueFollowupStage = 1;
        return const BotReply(
          text: 'I understand you lost something on campus. Don\'t worry, we\'re here to help!\n\n'
              'Could you tell me: What item did you lose, and where/when did you last see it?',
          quickReplies: [
            'Lost my phone in library',
            'Lost my bag in cafeteria',
            'Lost keys today',
          ],
        );
      }

      // If specific item or location is already provided with context
      final itemDesc = _state.rememberedItem ?? 'item';
      final locDesc = _state.rememberedLocation != null ? ' at ${_state.rememberedLocation}' : '';

      return BotReply(
        text: 'I\'m sorry to hear you lost your $itemDesc$locDesc. Let\'s get it reported right away!\n\n'
            'Steps to take:\n'
            '1. Tap "Report Lost Item" below to submit your case.\n'
            '2. Add description, date, and area so campus finders can identify it.\n'
            '3. Once an admin approves it, matching finders will be notified.',
        actions: [
          const BotAction(label: 'Report Lost Item', actionId: 'nav_post'),
        ],
        quickReplies: ['Track my case', 'How do claims work?'],
      );
    }

    // ── 8. Found Intent Detection (English + Hinglish) ──────────────────────
    // e.g. "found keys", "mujhe phone mila", "picked up a wallet", "i found something"
    if (_isFoundIntent(lower, tokens)) {
      _state.lastIntent = 'found';
      final itemDesc = _state.rememberedItem ?? 'item';

      return BotReply(
        text: 'Thank you for being an honest campus citizen! To report the found $itemDesc:\n\n'
            '1. Tap "Post Found Item" below.\n'
            '2. Add title, area found, and approximate time.\n'
            '3. Add 2 private verification questions that only the real owner can answer (e.g. wallpaper, keychain markings).\n'
            '4. Keep the item safe until campus admin and owner verify the match.',
        actions: [
          const BotAction(label: 'Report Found Item', actionId: 'nav_post'),
        ],
        quickReplies: ['What is the handover code?', 'How do claims work?'],
      );
    }

    // ── 9. Status / Progress Intent ────────────────────────────────────────
    // e.g. "track my case", "what is status", "under review", "mera case kahan hai"
    if (_isStatusIntent(lower, tokens)) {
      _state.lastIntent = 'status';
      final itemMention = _state.rememberedItem != null ? ' for your ${_state.rememberedItem}' : '';
      return BotReply(
        text: 'You can check the real-time status of all your cases$itemMention under "My Activity".\n\n'
            'Status stages:\n'
            '• Admin review: Admin checks the post is genuine\n'
            '• Claim pending: Claim submitted, answers being verified\n'
            '• Handover code: For high-value items, your 6-digit pickup OTP is shown here\n'
            '• Resolved: Item safely returned to owner!',
        actions: [
          const BotAction(label: 'Open My Activity', actionId: 'nav_activity'),
        ],
        quickReplies: ['What is the handover code?', 'Report lost item'],
      );
    }

    // ── 10. Handover Code / OTP Intent ─────────────────────────────────────
    if (lower.contains('handover') || lower.contains('otp') || lower.contains('code') || lower.contains('pickup code')) {
      _state.lastIntent = 'handover';
      return const BotReply(
        text: 'The 6-digit handover code secures high-value returns (phones, laptops, jewellery):\n\n'
            '• Visible ONLY to the verified claimant in their "My Activity" tab.\n'
            '• At the physical meetup, both check student IDs.\n'
            '• Claimant reads code aloud; finder enters it to close the case.',
        actions: [
          BotAction(label: 'My Activity', actionId: 'nav_activity'),
        ],
        quickReplies: ['Track my case', 'Report lost item'],
      );
    }

    // ── 11. Review / Trust Score Intent ────────────────────────────────────
    if (lower.contains('review') || lower.contains('trust') || lower.contains('rating') || lower.contains('stars') || lower.contains('feedback')) {
      _state.lastIntent = 'review';
      return const BotReply(
        text: 'Every student starts with a Trust Score of 50. When a case is resolved, both parties leave a 1-5 star review.\n\n'
            'Successful returns and honest verifications boost your campus reputation. Fake claims decrease trust.',
        quickReplies: ['Track my case', 'Report lost item'],
      );
    }

    // Default polite fallback with suggestion chips
    return const BotReply(
      text: 'I did not catch that. I am here to help you report lost or found items and track campus cases. Please pick a topic:',
      quickReplies: standardQuickReplies,
    );
  }

  BotReply _handleFollowUp(HelpContext ctx) {
    final item = _state.rememberedItem ?? 'case';
    switch (_state.lastIntent) {
      case 'lost':
        return BotReply(
          text: 'Regarding your lost $item:\n'
              '1. Submit a post with description and area.\n'
              '2. Once submitted, monitor the "My Activity" tab.\n'
              '3. You will receive an in-app notification when a finder match is confirmed.',
          actions: [const BotAction(label: 'Post Lost Item', actionId: 'nav_post')],
          quickReplies: ['Track my case', 'How do claims work?'],
        );
      case 'found':
        return BotReply(
          text: 'Regarding the found $item you reported:\n'
              '1. Wait for claimant answers to pass admin review.\n'
              '2. When notified, review the answers and confirm the owner.\n'
              '3. Meet publicly in the Student Center to complete handover.',
          actions: [const BotAction(label: 'My Activity', actionId: 'nav_activity')],
          quickReplies: ['What is the handover code?', 'Track my case'],
        );
      case 'claim':
        return const BotReply(
          text: 'For your active claim:\n'
              'Admin verifies your answers first. Once passed, the finder reviews and confirms. Check "My Activity" for updates.',
          actions: [BotAction(label: 'My Activity', actionId: 'nav_activity')],
          quickReplies: ['What is the handover code?', 'Report lost item'],
        );
      case 'status':
      default:
        return const BotReply(
          text: 'Head over to "My Activity" from the bottom dock to see real-time updates and pickup codes for all your reports.',
          actions: [BotAction(label: 'Go to My Activity', actionId: 'nav_activity')],
          quickReplies: ['Report lost item', 'Report found item'],
        );
    }
  }

  bool _isOutOfScope(String lower, Set<String> tokens) {
    const outOfScopeKeywords = [
      'joke', 'tell me a joke', 'laugh',
      'weather', 'forecast', 'rain today',
      'homework', 'assignment', 'essay', 'math', 'calculus', 'physics',
      'news', 'headline', 'politics', 'election', 'president',
      'recipe', 'cook', 'bake', 'food delivery',
      'song', 'music', 'sing',
      'who are you', 'how are you', 'what is your name',
      'capital of', 'translate', 'solve this',
      'code in python', 'write a poem', 'story',
    ];

    for (final kw in outOfScopeKeywords) {
      if (lower.contains(kw)) return true;
    }

    // Exclude general chatter tokens when not talking about lost & found
    if (tokens.contains('joke') || tokens.contains('homework') || tokens.contains('weather') || tokens.contains('recipe')) {
      return true;
    }

    return false;
  }

  bool _isFollowUpQuestion(String lower, Set<String> tokens) {
    const followUpPhrases = [
      'what should i do next',
      'what to do next',
      'what next',
      'whats next',
      'what\'s next',
      'what is its status',
      'what is the status',
      'what\'s the status',
      'what is my status',
      'kya karu abhi',
      'kya karoon',
      'ab kya karna hai',
      'next step',
      'then what',
    ];
    for (final p in followUpPhrases) {
      if (lower.contains(p)) return true;
    }
    return false;
  }

  bool _isLostIntent(String lower, Set<String> tokens) {
    // English keywords & typos
    if (lower.contains('lost') || lower.contains('loost') || lower.contains('misplaced') ||
        lower.contains('missing') || lower.contains('stolen') || lower.contains('took my') ||
        lower.contains('cannot find') || lower.contains('can\'t find') || lower.contains('cant find') ||
        lower.contains('drop my') || lower.contains('dropped my') || lower.contains('left my')) {
      return true;
    }

    // Hinglish patterns
    if (lower.contains('kho gaya') || lower.contains('kho gai') || lower.contains('kho gyi') ||
        lower.contains('gum ho gaya') || lower.contains('gum ho gya') || lower.contains('gum hogaya') ||
        lower.contains('bhul gaya') || lower.contains('chhut gaya') || lower.contains('chori')) {
      return true;
    }

    return false;
  }

  bool _isFoundIntent(String lower, Set<String> tokens) {
    // English keywords
    if (lower.contains('found') || lower.contains('picked up') || lower.contains('spotted an item') ||
        lower.contains('report found') || lower.contains('turned in') || lower.contains('discovered')) {
      // Avoid "I haven't found my..."
      if (lower.contains('haven\'t found') || lower.contains('havent found') || lower.contains('not found')) {
        return false;
      }
      return true;
    }

    // Hinglish patterns
    if (lower.contains('mila') || lower.contains('mili') || lower.contains('mujhe mila') ||
        lower.contains('padha mila') || lower.contains('paya gaya')) {
      return true;
    }

    return false;
  }

  bool _isClaimIntent(String lower, Set<String> tokens) {
    if (lower.contains('claim') || lower.contains('this is mine') || lower.contains('how to claim') ||
        lower.contains('verify answers') || lower.contains('answer questions') || lower.contains('mera saman hai')) {
      return true;
    }
    return false;
  }

  bool _isStatusIntent(String lower, Set<String> tokens) {
    if (lower.contains('status') || lower.contains('track') || lower.contains('under review') ||
        lower.contains('pending') || lower.contains('kahan tak pahuncha') || lower.contains('progress')) {
      return true;
    }
    return false;
  }
}

