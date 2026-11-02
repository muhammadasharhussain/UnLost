// test/items_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/data/models/item_model.dart';
import 'package:student_app/data/repositories/app_repository.dart';
import 'package:student_app/providers/items_provider.dart';

class DelayedFakeRepository implements AppRepository {
  final List<ItemModel> initialItemsList;
  Duration delay;
  int getItemsCallCount = 0;

  DelayedFakeRepository({
    required this.initialItemsList,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  Future<List<ItemModel>> getItems({
    String? type,
    String? category,
    String? search,
  }) async {
    getItemsCallCount++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    var list = List<ItemModel>.from(initialItemsList);
    if (type != null && type.isNotEmpty) {
      list = list.where((i) => i.type == type).toList();
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      list = list.where((i) => i.category == category).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((i) =>
          i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Future<List<ItemModel>> getMyItems() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ItemsProvider — Bug 2: Stale-While-Revalidate and Search Debounce', () {
    late DelayedFakeRepository repo;
    late ItemModel item1;
    late ItemModel item2;

    setUp(() {
      final now = DateTime.now();
      item1 = ItemModel(
        id: 'item_1',
        type: 'found',
        title: 'Blue Hydro Flask Bottle',
        category: 'other',
        description: 'Found near library',
        area: 'Library',
        dateTime: now,
        status: 'active',
        posterId: 'user_1',
        posterName: 'User One',
        posterTrustScore: 80,
        createdAt: now,
      );
      item2 = ItemModel(
        id: 'item_2',
        type: 'found',
        title: 'Dell XPS 15 Laptop',
        category: 'electronics',
        description: 'Left on study table',
        area: 'Library',
        dateTime: now,
        status: 'active',
        posterId: 'user_2',
        posterName: 'User Two',
        posterTrustScore: 90,
        createdAt: now,
      );

      repo = DelayedFakeRepository(
        initialItemsList: [item1, item2],
        delay: const Duration(milliseconds: 60),
      );
    });

    test('Initial load starts with isLoading = true, then populates items', () async {
      final provider = ItemsProvider(repo);

      // On creation, items is empty and isLoading is true (initial load)
      expect(provider.isLoading, isTrue);
      expect(provider.isRefreshing, isFalse);
      expect(provider.items, isEmpty);

      // Await repo delay
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isLoading, isFalse);
      expect(provider.isRefreshing, isFalse);
      expect(provider.items.length, equals(2));
    });

    test(
        'Typing, pausing and receiving search results never makes items empty or sets isLoading while previous items exist',
        () async {
      final provider = ItemsProvider(repo);

      // Complete initial load
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.items.length, equals(2));
      expect(provider.isLoading, isFalse);

      // User types in search bar: "Laptop"
      provider.onSearchChanged('Laptop');

      // Before debounce fires (e.g. 150ms in): items still untouched, not loading
      await Future.delayed(const Duration(milliseconds: 150));
      expect(provider.items.length, equals(2), reason: 'Items remain intact during typing');
      expect(provider.isLoading, isFalse);

      // Wait until debounce (300ms) has triggered loadItems
      // Debounce fires at 300ms, repo takes 60ms. At 330ms, loadItems is in-flight.
      await Future.delayed(const Duration(milliseconds: 180)); // total ~330ms

      // Stale-while-revalidate: isRefreshing is true, isLoading is FALSE, items still present!
      expect(provider.isLoading, isFalse, reason: 'isLoading must remain false when refreshing');
      expect(provider.isRefreshing, isTrue, reason: 'isRefreshing must be true');
      expect(provider.items.length, equals(2), reason: 'Stale items must remain visible');

      // Wait for search result to return
      await Future.delayed(const Duration(milliseconds: 80));

      expect(provider.isLoading, isFalse);
      expect(provider.isRefreshing, isFalse);
      expect(provider.items.length, equals(1));
      expect(provider.items.first.title, contains('Laptop'));
    });

    test('Category and type filters use stale-while-revalidate without resetting to placeholders', () async {
      final provider = ItemsProvider(repo);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.items.length, equals(2));

      // Change category
      provider.setActiveCategory('electronics');

      // Immediately: isLoading is false, isRefreshing is true, items still present
      expect(provider.isLoading, isFalse);
      expect(provider.isRefreshing, isTrue);
      expect(provider.items.length, equals(2));

      // Wait for response
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, isFalse);
      expect(provider.isRefreshing, isFalse);
      expect(provider.items.length, equals(1));
      expect(provider.items.first.category, equals('electronics'));
    });

    test('Ignores out-of-order responses using monotonic requestTag', () async {
      final provider = ItemsProvider(repo);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.items.length, equals(2));

      // Custom repo behavior: simulate out-of-order responses
      // Request A (search 'Bottle') triggered, but delayed 150ms
      // Request B (search 'Laptop') triggered quickly after, but finishes in 30ms
      repo.delay = const Duration(milliseconds: 150);
      provider.onSearchChanged('Bottle');

      // Wait for debounce to fire Request A (300ms)
      await Future.delayed(const Duration(milliseconds: 320));

      // Now immediately fire Request B with shorter delay
      repo.delay = const Duration(milliseconds: 30);
      provider.clearSearch(); // immediately calls loadItems with empty search

      // Wait for Request B to finish (30ms), before Request A finishes (~150ms)
      await Future.delayed(const Duration(milliseconds: 60));

      // Provider should now have Request B results (all 2 items)
      expect(provider.items.length, equals(2));

      // Wait for Request A's slow future to finally complete
      await Future.delayed(const Duration(milliseconds: 120));

      // Request A must be ignored because Request B had a newer tag
      expect(provider.items.length, equals(2),
          reason: 'Stale Request A should not overwrite Request B');
    });
  });
}
