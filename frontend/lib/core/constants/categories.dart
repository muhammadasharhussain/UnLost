// lib/core/constants/categories.dart
import 'package:flutter/cupertino.dart';

class CategoryConfig {
  final String id;
  final String name;
  final IconData icon;
  final bool isHighValue;
  final List<String> questions;

  const CategoryConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.isHighValue,
    required this.questions,
  });
}

class ItemCategories {
  static const List<CategoryConfig> all = [
    CategoryConfig(
      id: 'wallet',
      name: 'Wallets & Purses',
      icon: CupertinoIcons.creditcard,
      isHighValue: true,
      questions: [
        'How many payment or identity cards are inside?',
        'Is there any cash, receipts, or photos inside, and in what amount/description?',
      ],
    ),
    CategoryConfig(
      id: 'phone',
      name: 'Smartphones',
      icon: CupertinoIcons.device_phone_portrait,
      isHighValue: true,
      questions: [
        'What color is the phone case or lock screen wallpaper?',
        'What is the lock screen carrier name or any distinguishing scratch/sticker?',
      ],
    ),
    CategoryConfig(
      id: 'electronics',
      name: 'Laptops & Gadgets',
      icon: CupertinoIcons.device_laptop,
      isHighValue: true,
      questions: [
        'What specific brand/model and what stickers or case covers are on it?',
        'What accessories (charger, dongle, sleeve color) accompanied it?',
      ],
    ),
    CategoryConfig(
      id: 'documents',
      name: 'IDs & Documents',
      icon: CupertinoIcons.doc_text,
      isHighValue: true,
      questions: [
        'What full name and department/program is printed on the card or paper?',
        'What is the lanyard color or sleeve type holding the document?',
      ],
    ),
    CategoryConfig(
      id: 'bag',
      name: 'Bags & Backpacks',
      icon: CupertinoIcons.bag,
      isHighValue: true,
      questions: [
        'What key items or notebooks are inside the main compartment?',
        'Are there any keychains, pins, or specific brand tags on the exterior?',
      ],
    ),
    CategoryConfig(
      id: 'jewellery',
      name: 'Jewellery & Watches',
      icon: CupertinoIcons.sparkles,
      isHighValue: true,
      questions: [
        'What metal color, engraving, or specific gem setting does it have?',
        'What brand or clasp mechanism does it feature?',
      ],
    ),
    CategoryConfig(
      id: 'keys',
      name: 'Keys & Fobs',
      icon: CupertinoIcons.lock,
      isHighValue: false,
      questions: [
        'How many keys are on the ring and what color is the keychain fob?',
        'Is there any distinctive car logo, tag number, or decorative charm?',
      ],
    ),
    CategoryConfig(
      id: 'clothing',
      name: 'Clothing & Jackets',
      icon: CupertinoIcons.tag,
      isHighValue: false,
      questions: [
        'What is the exact clothing size, brand, and primary color?',
        'Was there anything left inside the pockets or any unique tear/mark?',
      ],
    ),
    CategoryConfig(
      id: 'books',
      name: 'Books & Stationery',
      icon: CupertinoIcons.book,
      isHighValue: false,
      questions: [
        'What is the course code, subject name, or notes written on the first page?',
        'What color or bookmark was found inside the pages?',
      ],
    ),
    CategoryConfig(
      id: 'other',
      name: 'Other Items',
      icon: CupertinoIcons.cube_box,
      isHighValue: false,
      questions: [
        'What is the exact color, material, or brand of the item?',
        'What unique imperfection, marking, or contents verify your ownership?',
      ],
    ),
  ];

  static CategoryConfig getById(String id) {
    return all.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
      orElse: () => all.last,
    );
  }

  static List<String> getQuestionsForCategory(String categoryIdOrName) {
    final cat = all.firstWhere(
      (c) =>
          c.id.toLowerCase() == categoryIdOrName.toLowerCase() ||
          c.name.toLowerCase() == categoryIdOrName.toLowerCase(),
      orElse: () => all.last,
    );
    return cat.questions;
  }

  static bool isHighValueCategory(String categoryIdOrName) {
    final cat = all.firstWhere(
      (c) =>
          c.id.toLowerCase() == categoryIdOrName.toLowerCase() ||
          c.name.toLowerCase() == categoryIdOrName.toLowerCase(),
      orElse: () => all.last,
    );
    return cat.isHighValue;
  }
}
