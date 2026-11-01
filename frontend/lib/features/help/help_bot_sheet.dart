// lib/features/help/help_bot_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'help_bot_engine.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<BotAction> actions;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions = const [],
  });
}

class HelpBotSheet extends StatefulWidget {
  final HelpContext contextData;
  final void Function(String actionId)? onAction;

  const HelpBotSheet({
    super.key,
    required this.contextData,
    this.onAction,
  });

  static Future<void> show(
    BuildContext context, {
    required HelpContext contextData,
    void Function(String actionId)? onAction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HelpBotSheet(
        contextData: contextData,
        onAction: onAction,
      ),
    );
  }

  @override
  State<HelpBotSheet> createState() => _HelpBotSheetState();
}

class _HelpBotSheetState extends State<HelpBotSheet> {
  final HelpBotEngine _engine = LocalHelpBotEngine();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  List<String> _quickReplies = LocalHelpBotEngine.defaultQuickReplies;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: 'Hi there! I am your Unlost campus assistant. How can I help you find or report items today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    final reply = await _engine.reply(query, widget.contextData);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply.text,
            isUser: false,
            actions: reply.actions,
          ),
        );
        _quickReplies = reply.quickReplies;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    final cardBg = dark ? AppColors.darkCard : AppColors.lightCard;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final emerald = dark ? AppColors.emerald : AppColors.emeraldInk;
    final champagne = dark ? AppColors.champagne : AppColors.champagneInk;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.textFaint.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.question_circle_fill, color: emerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlost Campus Guide',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.palette.text,
                          ),
                        ),
                        Text(
                          'Automated Assistant • Offline',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFontFamily,
                            fontSize: 10,
                            color: context.palette.textFaint,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(CupertinoIcons.clear, color: context.palette.textDim, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),

          // Message history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? (dark ? emerald : AppColors.emeraldInk)
                            : (dark ? AppColors.darkSurface : AppColors.lightSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: msg.isUser ? Colors.transparent : border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: msg.isUser
                                  ? (dark ? AppColors.onEmerald : Colors.white)
                                  : context.palette.text,
                            ),
                          ),
                          if (msg.actions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: msg.actions.map((act) {
                                return ElevatedButton.icon(
                                  icon: const Icon(CupertinoIcons.arrow_right_circle, size: 14),
                                  label: Text(act.label),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    backgroundColor: champagne,
                                    foregroundColor: AppColors.onChampagne,
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onAction?.call(act.actionId);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Unlost is typing...',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: emerald,
                  ),
                ),
              ),
            ),

          // Quick-reply chips
          if (_quickReplies.isNotEmpty)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final reply = _quickReplies[idx];
                  return ActionChip(
                    label: Text(reply),
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.monoFontFamily,
                      fontSize: 11,
                      color: context.palette.text,
                    ),
                    backgroundColor: dark ? AppColors.darkSurface : AppColors.lightSurface,
                    side: BorderSide(color: border),
                    onPressed: () => _sendMessage(reply),
                  );
                },
              ),
            ),

          // Input field
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: _sendMessage,
                    style: TextStyle(fontSize: 14, color: context.palette.text),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: TextStyle(fontSize: 14, color: context.palette.textFaint),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send',
                  icon: Icon(CupertinoIcons.arrow_up_circle_fill, color: emerald, size: 36),
                  onPressed: () => _sendMessage(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
