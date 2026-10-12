// lib/ui/claims/handover_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/claims_provider.dart';
import '../../core/widgets/app_backdrop.dart';

class HandoverScreen extends StatefulWidget {
  final String claimId;

  const HandoverScreen({
    super.key,
    required this.claimId,
  });

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  bool _idPhysicalChecked = false;
  bool _idPhotoMatches = false;
  bool _studentEnrollmentVerified = false;

  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isChecklistComplete =>
      _idPhysicalChecked && _idPhotoMatches && _studentEnrollmentVerified;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyHandover() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the handover code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final claimsProv = context.read<ClaimsProvider>();
    final success = await claimsProv.confirmHandover(widget.claimId, code);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      setState(() {
        _errorMessage = claimsProv.errorMessage ?? 'Invalid handover code.';
      });
    }
  }

  void _showSuccessDialog() {
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
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 36,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Handover Completed!',
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
                'Item is officially resolved and returned to its owner. '
                'Both your trust score and the claimant\'s trust score have been increased by campus verification rewards.',
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
                  Navigator.pop(context); // Close handover screen
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
        title: const Text('Handover Verification'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-Value Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.lock_shield_fill,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'High-Value Item Protocol',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'For security, verify the claimant\'s physical university ID card before entering the handover code.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: ID Checklist Section
            Text(
              'Step 1: University ID Checklist',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All items below must be physically verified before the code entry unlocks:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _idPhysicalChecked,
                    onChanged: (val) =>
                        setState(() => _idPhysicalChecked = val ?? false),
                    title: const Text('Inspected physical university student ID card',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: _idPhotoMatches,
                    onChanged: (val) =>
                        setState(() => _idPhotoMatches = val ?? false),
                    title: const Text('ID card photo and name match claimant in person',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: _studentEnrollmentVerified,
                    onChanged: (val) =>
                        setState(() => _studentEnrollmentVerified = val ?? false),
                    title: const Text('Card is current and valid for active semester',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Step 2: 6-Digit Handover Code Entry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 2: Enter 6-Digit Handover Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (!_isChecklistComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightCardSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LOCKED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Ask the claimant to read their secret 6-digit handover code aloud from their Unlost app.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Code input field
            TextField(
              controller: _codeController,
              enabled: _isChecklistComplete,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                fillColor: _isChecklistComplete
                    ? (isDark ? AppColors.darkCard : Colors.white)
                    : (isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),

            // Confirm Handover Button
            CustomButton(
              text: 'Confirm Handover & Resolve',
              onPressed: _isChecklistComplete ? _verifyHandover : null,
              isLoading: _isSubmitting,
              variant: ButtonVariant.primary,
              icon: CupertinoIcons.checkmark_shield_fill,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }
}
