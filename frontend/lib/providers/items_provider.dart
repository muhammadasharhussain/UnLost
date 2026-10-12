// lib/providers/items_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/repositories/app_repository.dart';

class ItemsProvider extends ChangeNotifier {
  final AppRepository _repository;

  List<ItemModel> _items = [];
  List<ItemModel> _myItems = [];
  bool _isLoading = false;
  bool _isLoadingMyItems = false;
  String? _errorMessage;
  String? _myItemsErrorMessage;

  String _activeType = 'found'; // 'found' | 'lost'
  String _activeCategory = 'all';
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<ItemModel> get items => _items;
  List<ItemModel> get myItems => _myItems;
  bool get isLoading => _isLoading;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getItems(
        type: _activeType,
        category: _activeCategory == 'all' ? null : _activeCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
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
        hiddenFields: null, // Lost posts don't have verification questions
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
