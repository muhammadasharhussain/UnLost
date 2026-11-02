// lib/providers/items_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/repositories/app_repository.dart';

class ItemsProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ItemModel> _items = [];
  List<ItemModel> _myItems = [];

  /// True only during the very first load when there is nothing to show yet.
  bool _isLoading = false;

  /// True whenever a background refresh is in-flight while stale data is shown.
  /// Screens use this to render a thin LinearProgressIndicator, NOT placeholders.
  bool _isRefreshing = false;

  bool _isLoadingMyItems = false;
  String? _errorMessage;
  String? _myItemsErrorMessage;

  String _activeType = 'found'; // 'found' | 'lost'
  String _activeCategory = 'all';
  String _searchQuery = '';
  Timer? _debounceTimer;

  /// Monotonic counter. Each call to loadItems captures its own tag;
  /// if a newer call finishes first, older responses are silently dropped.
  int _requestTag = 0;

  List<ItemModel> get items => _items;
  List<ItemModel> get myItems => _myItems;

  /// True only on initial empty load — shows full skeleton.
  bool get isLoading => _isLoading;

  /// True during a background refresh — shows thin top bar, not placeholders.
  bool get isRefreshing => _isRefreshing;

  bool get isLoadingMyItems => _isLoadingMyItems;
  String? get errorMessage => _errorMessage;
  String? get myItemsErrorMessage => _myItemsErrorMessage;
  String get activeType => _activeType;
  String get activeCategory => _activeCategory;
  String get searchQuery => _searchQuery;

  ItemsProvider(this._repository) {
    loadItems();
    loadMyItems();
  }

  Future<void> loadItems() async {
    final hasData = _items.isNotEmpty;

    if (!hasData) {
      // First load — nothing to show yet, use the full loading state.
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      // Subsequent refresh — keep the existing list, show a thin indicator.
      _isRefreshing = true;
      notifyListeners();
    }

    // Capture the tag for this particular request.
    _requestTag++;
    final myTag = _requestTag;

    try {
      final result = await _repository.getItems(
        type: _activeType,
        category: _activeCategory == 'all' ? null : _activeCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // Discard if a newer request already completed.
      if (myTag != _requestTag) return;

      _items = result;
      _errorMessage = null;
    } catch (e) {
      if (myTag != _requestTag) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (myTag == _requestTag) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMyItems() async {
    _isLoadingMyItems = true;
    _myItemsErrorMessage = null;
    notifyListeners();

    try {
      _myItems = await _repository.getMyItems();
      _isLoadingMyItems = false;
      notifyListeners();
    } catch (e) {
      _myItemsErrorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoadingMyItems = false;
      notifyListeners();
    }
  }

  void setActiveType(String type) {
    if (_activeType == type) return;
    _activeType = type;
    loadItems();
  }

  void setActiveCategory(String category) {
    if (_activeCategory == category) return;
    _activeCategory = category;
    loadItems();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadItems();
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _debounceTimer?.cancel();
    loadItems();
  }

  Future<ItemModel?> postFoundItem({
    required String title,
    required String category,
    required String description,
    required String area,
    required DateTime dateTime,
    required List<String> hiddenFields,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _repository.createItem(
        type: 'found',
        title: title,
        category: category,
        description: description,
        area: area,
        dateTime: dateTime,
        hiddenFields: hiddenFields,
      );
      _isLoading = false;
      await loadMyItems();
      return item;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<ItemModel?> postLostItem({
    required String title,
    required String category,
    required String description,
    required String area,
    required DateTime dateTime,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _repository.createItem(
        type: 'lost',
        title: title,
        category: category,
        description: description,
        area: area,
        dateTime: dateTime,
        hiddenFields: null, // Lost posts do not have verification questions
      );
      _isLoading = false;
      await loadMyItems();
      return item;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<ItemModel> getItemById(String id) async {
    return _repository.getItemById(id);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
