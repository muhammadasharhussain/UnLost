// lib/ui/claims/finder_claim_screen.dart
// "I found this": a finder describes what they found for someone's LOST report.
// The claim goes to the admin queue first, then to the owner.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_backdrop.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/item_model.dart';
import '../../providers/claims_provider.dart';

class FinderClaimScreen extends StatefulWidget {
  final ItemModel item; // the LOST report

  const FinderClaimScreen({super.key, required this.item});

  @override
  State<FinderClaimScreen> createState() => _FinderClaimScreenState();
}

class _FinderClaimScreenState extends State<FinderClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final claimsProv = context.read<ClaimsProvider>();
    final claim = await claimsProv.submitFinderClaim(
      itemId: widget.item.id,
      foundDescription: _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (claim != null) {
      _showSentDialog();
    } else {
      setState(() => _error = claimsProv.errorMessage ?? 'Could not send. Try again.');
    }
  }

  void _showSentDialog() {
    final p = context.palette;
    final accent = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.hairline, width: 1.5),
        ),
        backgroundColor: p.isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.hand_raised_fill, size: 34, color: accent),
              const SizedBox(height: 16),
              Text(
                'Sent to admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.displayFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An admin checks your message first. If it passes, the owner sees it and '
                'answers "This is mine" or "Not mine". Follow it under My Activity.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: p.textDim),
              ),
              const SizedBox(height: 22),
              CustomButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(ctx); // dialog
                  Navigator.pop(context); // form
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
    final p = context.palette;
    final accent = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('I found this'),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.hairline, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOST REPORT',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: p.isDark ? AppColors.champagne : AppColors.champagneInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.title,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.area,
                        style: TextStyle(fontSize: 13, color: p.textDim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.info_circle_fill, size: 18, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Describe what you found in your own words: brand, marks, stickers, '
                          'where it is now. Details only the real owner would recognise help most.',
                          style: TextStyle(fontSize: 13, height: 1.4, color: p.text),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'What did you find, and where is it now?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _descController,
                  hintText: 'e.g. Black Sony headphones, scratch on the left cup. I handed them to the library desk.',
                  maxLines: 5,
                  validator: (v) {
                    if (v == null || v.trim().length < 15) {
                      return 'Please write at least a short sentence (15+ characters).';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.readable(
                          AppColors.error, Theme.of(context).brightness),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Send to admin',
                  icon: CupertinoIcons.paperplane_fill,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                  variant: ButtonVariant.primary,
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
