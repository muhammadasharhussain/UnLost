// lib/ui/items/post_lost_screen.dart
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

class PostLostScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialTitle;
  final String? initialArea;

  const PostLostScreen({
    super.key,
    this.initialCategory,
    this.initialTitle,
    this.initialArea,
  });

  @override
  State<PostLostScreen> createState() => _PostLostScreenState();
}

class _PostLostScreenState extends State<PostLostScreen> {
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: What, 2: Where & When, 3: Details & Post

  late String _selectedCategory;
  late String _selectedArea;
  late DateTime _selectedDate;
  String _dateOption = 'today'; // 'today', 'yesterday', 'other'
  bool _isOtherArea = false;
  final _otherAreaController = TextEditingController();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

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
    super.dispose();
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
        const SnackBar(content: Text('Please enter a brief item name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final finalArea = _isOtherArea && _otherAreaController.text.trim().isNotEmpty
        ? _otherAreaController.text.trim()
        : _selectedArea;

    final itemsProv = context.read<ItemsProvider>();
    final item = await itemsProv.postLostItem(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      area: finalArea,
      dateTime: _selectedDate,
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
                'Report Submitted!',
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
                  'Sent to campus admin for review. Possible matching found items:',
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
                    'No immediate matches yet. You will be notified when someone reports finding this.',
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

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('I lost something'),
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
                          title: '1. What item did you lose?',
                          subtitle: 'Tap the category that best describes it',
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
                          title: 'Item name',
                          subtitle: 'e.g. Blue HP Pavilion Laptop, Student ID',
                          child: CustomTextField(
                            controller: _titleController,
                            hintText: 'What was it called?',
                            prefixIcon: const Icon(CupertinoIcons.tag, size: 18),
                          ),
                        ),
                      ] else if (_step == 2) ...[
                        // Step 2: Where & When
                        SectionPanel(
                          title: '2. Where did you lose it?',
                          subtitle: 'Pick campus place or type a specific spot',
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
                                  hintText: 'Specific room, bench or bus stop',
                                  prefixIcon: const Icon(CupertinoIcons.location, size: 18),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SectionPanel(
                          title: 'When was it lost?',
                          subtitle: 'Pick approx date',
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
                        // Step 3: Description & Submit
                        SectionPanel(
                          title: '3. Any unique markings or details?',
                          subtitle: 'Color, stickers, scratches or wallpaper',
                          child: CustomTextField(
                            controller: _descriptionController,
                            hintText: 'Add short description to help identify it',
                            maxLines: 3,
                          ),
                        ),
                        SectionPanel(
                          title: 'Review Summary',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summaryRow('Item:', _titleController.text.isEmpty ? 'Untitled' : _titleController.text),
                              _summaryRow('Category:', ItemCategories.getById(_selectedCategory).name),
                              _summaryRow('Place:', _isOtherArea && _otherAreaController.text.isNotEmpty ? _otherAreaController.text : _selectedArea),
                              _summaryRow('Date:', DateFormat('EEEE, MMM d').format(_selectedDate)),
                            ],
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
                        text: 'Post Lost Report',
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: context.palette.textDim,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
