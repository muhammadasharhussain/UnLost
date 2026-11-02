// lib/ui/items/post_found_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/matching/case_recommender.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_backdrop.dart';
import '../../core/widgets/case_card.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/section_panel.dart';
import '../../data/models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import 'item_detail_screen.dart';

class PostFoundScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialTitle;
  final String? initialArea;

  const PostFoundScreen({
    super.key,
    this.initialCategory,
    this.initialTitle,
    this.initialArea,
  });

  @override
  State<PostFoundScreen> createState() => _PostFoundScreenState();
}

class _PostFoundScreenState extends State<PostFoundScreen> {
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: What, 2: Where & When, 3: Verification & Post

  late String _selectedCategory;
  late String _selectedArea;
  late DateTime _selectedDate;
  String _dateOption = 'today';
  bool _isOtherArea = false;
  final _otherAreaController = TextEditingController();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? ItemCategories.all.first.id;
    _selectedArea = widget.initialArea ?? AppConstants.campusAreas.first;
    _selectedDate = DateTime.now();

    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _otherAreaController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  List<String> get _currentQuestions {
    return ItemCategories.getQuestionsForCategory(_selectedCategory);
  }

  Future<void> _pickCustomDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = pickedDate;
      _dateOption = 'other';
    });
  }

  void _setDateOption(String opt) {
    setState(() {
      _dateOption = opt;
      if (opt == 'today') {
        _selectedDate = DateTime.now();
      } else if (opt == 'yesterday') {
        _selectedDate = DateTime.now().subtract(const Duration(days: 1));
      }
    });
  }

  Future<void> _submitForm() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }
    if (_answer1Controller.text.trim().isEmpty || _answer2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer both verification questions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final finalArea = _isOtherArea && _otherAreaController.text.trim().isNotEmpty
        ? _otherAreaController.text.trim()
        : _selectedArea;

    final itemsProv = context.read<ItemsProvider>();
    final item = await itemsProv.postFoundItem(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      area: finalArea,
      dateTime: _selectedDate,
      hiddenFields: [
        _answer1Controller.text.trim(),
        _answer2Controller.text.trim(),
      ],
    );

    setState(() => _isSubmitting = false);

    if (item != null && mounted) {
      _showSubmittedWithMatches(item);
    }
  }

  void _showSubmittedWithMatches(ItemModel postedItem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemsProv = context.read<ItemsProvider>();
    final auth = context.read<AuthProvider>();
    final viewerId = auth.currentUser?.id ?? '';
    final isAdmin = auth.currentUser?.isAdmin == true;

    final recs = CaseRecommender.recommend(postedItem, itemsProv.items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: isDark ? AppColors.emerald : AppColors.emeraldInk,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Found Item Posted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Sent to campus admin for approval. Potential lost reports matching this item:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (recs.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    itemCount: recs.length,
                    itemBuilder: (context, idx) {
                      final match = recs[idx].item;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CaseCard(
                          item: match,
                          viewerId: viewerId,
                          viewerIsAdmin: isAdmin,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(itemId: match.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No direct lost reports found yet. The item will be displayed on the feed once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: CustomButton(
                  text: 'Done',
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDarkMode;
    final questions = _currentQuestions;

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('I found something'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: p.text, size: 20),
            onPressed: () {
              if (_step > 1) {
                setState(() => _step--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Step progress header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Step $_step of 3',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.coral : AppColors.coralInk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _step / 3.0,
                          backgroundColor: p.hairline,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.coral : AppColors.coralInk,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_step == 1) ...[
                        // Step 1: Category & Name
                        SectionPanel(
                          title: '1. What did you find?',
                          subtitle: 'Pick the category to set appropriate verification questions',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ItemCategories.all.map((cat) {
                              final sel = _selectedCategory == cat.id;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cat.icon, size: 16),
                                    const SizedBox(width: 6),
                                    Text(cat.name),
                                  ],
                                ),
                                selected: sel,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat.id),
                              );
                            }).toList(),
                          ),
                        ),
                        SectionPanel(
                          title: 'Item title',
                          subtitle: 'e.g. Silver AirPods Case, Black Leather Wallet',
                          child: CustomTextField(
                            controller: _titleController,
                            hintText: 'What did you find?',
                            prefixIcon: const Icon(CupertinoIcons.tag, size: 18),
                          ),
                        ),
                      ] else if (_step == 2) ...[
                        // Step 2: Where & When
                        SectionPanel(
                          title: '2. Where did you find it?',
                          subtitle: 'Pick campus place or specify location',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...AppConstants.campusAreas.map((area) {
                                    final sel = !_isOtherArea && _selectedArea == area;
                                    return ChoiceChip(
                                      label: Text(area),
                                      selected: sel,
                                      onSelected: (_) => setState(() {
                                        _selectedArea = area;
                                        _isOtherArea = false;
                                      }),
                                    );
                                  }),
                                  ChoiceChip(
                                    label: const Text('Other spot...'),
                                    selected: _isOtherArea,
                                    onSelected: (_) => setState(() => _isOtherArea = true),
                                  ),
                                ],
                              ),
                              if (_isOtherArea) ...[
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: _otherAreaController,
                                  hintText: 'Specific desk, bench or area',
                                  prefixIcon: const Icon(CupertinoIcons.location, size: 18),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SectionPanel(
                          title: 'When was it found?',
                          subtitle: 'Select date',
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Today'),
                                selected: _dateOption == 'today',
                                onSelected: (_) => _setDateOption('today'),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Yesterday'),
                                selected: _dateOption == 'yesterday',
                                onSelected: (_) => _setDateOption('yesterday'),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(
                                  _dateOption == 'other'
                                      ? DateFormat('MMM d').format(_selectedDate)
                                      : 'Pick date',
                                ),
                                selected: _dateOption == 'other',
                                onSelected: (_) => _pickCustomDate(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Step 3: Verification Questions & Details
                        SectionPanel(
                          title: '3. Private Verification Questions',
                          subtitle:
                              'Answers stay hidden. Admins use these to verify real owners.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questions[0],
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              CustomTextField(
                                controller: _answer1Controller,
                                hintText: 'Your secret answer',
                                prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                questions[1],
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              CustomTextField(
                                controller: _answer2Controller,
                                hintText: 'Your secret answer',
                                prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                              ),
                            ],
                          ),
                        ),
                        SectionPanel(
                          title: 'Optional note to admin',
                          subtitle: 'Safe place where item is kept (e.g. Reception desk)',
                          child: CustomTextField(
                            controller: _descriptionController,
                            hintText: 'Where the item is currently kept',
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom action bar: Single primary button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _step < 3
                    ? CustomButton(
                        text: 'Continue',
                        variant: ButtonVariant.primary,
                        onPressed: () {
                          if (_step == 1 && _titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter an item name')),
                            );
                            return;
                          }
                          setState(() => _step++);
                        },
                      )
                    : CustomButton(
                        text: 'Post Found Report',
                        isLoading: _isSubmitting,
                        variant: ButtonVariant.primary,
                        onPressed: _submitForm,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
