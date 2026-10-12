// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/app_repository.dart';

class ChatProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChatProvider(this._repository);

  Future<void> loadMessages(String claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(claimId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String claimId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      final msg = await _repository.sendMessage(claimId, text.trim());
      _messages.add(msg);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
