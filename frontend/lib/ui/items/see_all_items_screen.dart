// lib/ui/items/see_all_items_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/widgets/app_backdrop.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/section_panel.dart';
import '../../data/models/item_model.dart';
import '../../providers/auth_provider.dart';
import 'item_detail_screen.dart';

class SeeAllItemsScreen extends StatefulWidget {
  final String title;
  final List<ItemModel> items;

  const SeeAllItemsScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<SeeAllItemsScreen> createState() => _SeeAllItemsScreenState();
}

class _SeeAllItemsScreenState extends State<SeeAllItemsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final viewerId = auth.currentUser?.id ?? '';
    final isAdmin = auth.currentUser?.isAdmin == true;

    final filtered = _selectedCategory == 'all'
        ? widget.items
        : widget.items.where((i) => i.category == _selectedCategory).toList();

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Category filter inside a panel
              SectionPanel(
                title: 'Filter by Category',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All items'),
                          selected: _selectedCategory == 'all',
                          onSelected: (_) =>
                              setState(() => _selectedCategory = 'all'),
                        ),
                      ),
                      ...ItemCategories.all.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: _selectedCategory == c.id,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = c.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SectionPanel(
                  title: 'No items found',
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No items in this category yet.'),
                    ),
                  ),
                )
              else
                ...filtered.map((item) {
                  return SectionPanel(
                    title: item.title,
                    subtitle: '${item.area} • ${item.isFound ? "Found report" : "Lost report"}',
                    child: CaseCard(
                      item: item,
                      viewerId: viewerId,
                      viewerIsAdmin: isAdmin,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(itemId: item.id),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
