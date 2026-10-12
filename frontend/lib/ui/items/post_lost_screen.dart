// lib/ui/items/post_lost_screen.dart
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

  late String _selectedCategory;
  late String _selectedArea;
  late DateTime _selectedDate;

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
    super.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final itemsProv = context.read<ItemsProvider>();
    final item = await itemsProv.postLostItem(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      area: _selectedArea,
      dateTime: _selectedDate,
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
                'Your lost item report has been submitted to campus administrators for approval. '
                'Once approved, it will be published to the campus Lost feed.',
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
                  Navigator.pop(ctx);
                  Navigator.pop(context);
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

    return AppBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Report Lost Item'),
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
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill,
                        size: 20, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lost reports notify fellow students and campus staff. All lost listings are verified by an administrator before appearing live.',
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
                'Category',
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
                              activeColor: AppColors.warning,
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
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
                labelText: 'Item Name / Title',
                hintText: 'e.g. Sony WF-1000XM4 Wireless Earbuds',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for the lost item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Detailed Description',
                hintText: 'Describe distinctive features, color, brand, condition, or circumstances of losing it.',
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a detailed description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campus Location Picker
              Text(
                'Approximate Campus Area Lost',
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

              // Date Picker
              Text(
                'Date & Time Estimated Lost',
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
              const SizedBox(height: 36),

              // Submit Button
              CustomButton(
                text: 'Submit Lost Report',
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
