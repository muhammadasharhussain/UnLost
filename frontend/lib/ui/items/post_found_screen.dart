// lib/ui/items/post_found_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/hover_color_icon.dart';
import '../../providers/items_provider.dart';
import '../../core/widgets/app_backdrop.dart';

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

  late String _selectedCategory;
  late String _selectedArea;
  late DateTime _selectedDate;

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
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  List<String> get _currentQuestions {
    return ItemCategories.getQuestionsForCategory(_selectedCategory);
  }

  bool get _isHighValue {
    return ItemCategories.isHighValueCategory(_selectedCategory);
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  bool _checkGenericAnswers() {
    final a1 = _answer1Controller.text.trim();
    final a2 = _answer2Controller.text.trim();
    return a1.length < 8 || a2.length < 8;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkGenericAnswers()) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Brief Answers Detected'),
          content: const Text(
            'Your verification answers are quite short. Adding more descriptive details helps the campus admin and true owner verify ownership accurately. Do you want to submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Edit Answers'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);
    if (!mounted) return;
    final itemsProv = context.read<ItemsProvider>();
    final item = await itemsProv.postFoundItem(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      area: _selectedArea,
      dateTime: _selectedDate,
      hiddenFields: [
        _answer1Controller.text.trim(),
        _answer2Controller.text.trim(),
      ],
    );

    setState(() => _isSubmitting = false);

    if (item != null && mounted) {
      _showSubmittedDialog();
    }
  }

  void _showSubmittedDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.hourglass,
                  size: 32,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sent for Admin Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your found post has been placed in the campus administration review queue. '
                'Once approved, it will appear publicly on the campus feed. You can track its status under My Activity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to feed
                },
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questions = _currentQuestions;

    return AppBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Post Found Item'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.shield_lefthalf_fill,
                        size: 20, color: AppColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Found posts undergo mandatory verification. Keep the answers private; only potential claimants will be prompted with the questions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(
                'Select Item Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    items: ItemCategories.all.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Row(
                          children: [
                            HoverColorIcon(
                              icon: c.icon,
                              size: 18,
                              activeColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (c.isHighValue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HIGH VALUE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              CustomTextField(
                controller: _titleController,
                labelText: 'Item Title',
                hintText: 'e.g. Leather Bifold Wallet',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for the item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Public Description',
                hintText: 'Describe visual details (color, general location, condition). Do not include private contents!',
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a brief description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campus Location Picker
              Text(
                'Campus Location Found',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedArea,
                    isExpanded: true,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    items: AppConstants.campusAreas.map((area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(
                          area,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedArea = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker Tile
              Text(
                'Date & Time Recovered',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEE, MMM d, yyyy • h:mm a').format(_selectedDate),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(CupertinoIcons.pencil, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── System-Generated Verification Questions Section ──────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isHighValue
                        ? AppColors.warning.withValues(alpha: 0.4)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _isHighValue ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock_shield,
                          size: 18,
                          color: _isHighValue ? AppColors.warning : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Automated Verification Questions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'These questions are automatically selected for "$_selectedCategory". Enter your private answers so legitimate claimants can be accurately matched.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Question 1
                    Text(
                      '1. ${questions[0]}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _answer1Controller,
                      hintText: 'Enter your answer (private to finder & admin)',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Answer 1 is required for verification';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Question 2
                    Text(
                      '2. ${questions[1]}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _answer2Controller,
                      hintText: 'Enter your answer (private to finder & admin)',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Answer 2 is required for verification';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Submit for Review',
                onPressed: _submitForm,
                isLoading: _isSubmitting,
                variant: ButtonVariant.primary,
                icon: CupertinoIcons.paperplane_fill,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
