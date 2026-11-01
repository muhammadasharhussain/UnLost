// lib/features/reviews/review_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/review_logic.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/reviews_provider.dart';

/// Row of five stars. Read-only when [onChanged] is null.
class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lit = p.isDark ? AppColors.rose : AppColors.roseInk;

    return Semantics(
      label: '$rating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < rating;
          final icon = Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? lit : p.textFaint,
          );
          if (onChanged == null) return icon;
          return Semantics(
            button: true,
            label: 'Rate ${i + 1} star${i == 0 ? '' : 's'}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged!(i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: icon,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Small selectable pill used for outcome and tags.
class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.isDark ? AppColors.rose : AppColors.roseInk;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : p.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: selected ? accent : p.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

/// "How did it go?" bottom sheet. Skippable. One review per person per case.
class ReviewSheet extends StatefulWidget {
  final String caseId;
  final String viewerId;
  final String aboutUserId;
  final String aboutName;

  const ReviewSheet({
    super.key,
    required this.caseId,
    required this.viewerId,
    required this.aboutUserId,
    required this.aboutName,
  });

  /// Returns true when a review was submitted.
  static Future<bool> show(
    BuildContext context, {
    required String caseId,
    required String viewerId,
    required String aboutUserId,
    required String aboutName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewSheet(
        caseId: caseId,
        viewerId: viewerId,
        aboutUserId: aboutUserId,
        aboutName: aboutName,
      ),
    );
    return result == true;
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  String _outcome = kReviewOutcomes.first;
  final Set<String> _tags = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Tap a star rating first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final err = await context.read<ReviewsProvider>().submit(
          viewerId: widget.viewerId,
          caseId: widget.caseId,
          aboutUserId: widget.aboutUserId,
          rating: _rating,
          outcome: _outcome,
          tags: _tags.toList(),
          comment: _commentController.text,
        );

    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.isDark ? AppColors.rose : AppColors.roseInk;
    final firstName = widget.aboutName.trim().split(' ').first;
    final lowRatingWithComment =
        isFlaggedRating(_rating == 0 ? 5 : _rating, _commentController.text);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.isDark ? AppColors.darkSurface : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: p.hairline, width: 1.5)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'CASE CLOSED',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How did it go?',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rate your experience with $firstName. Reviews are shown on profiles. '
                  'They do not change anyone\'s trust score.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: p.textDim),
                ),
                const SizedBox(height: 16),
                StarRating(
                  rating: _rating,
                  size: 34,
                  onChanged: (v) => setState(() {
                    _rating = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 14),
                _label(context, 'OUTCOME'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in kReviewOutcomes)
                      _ChoicePill(
                        label: o,
                        selected: _outcome == o,
                        onTap: () => setState(() => _outcome = o),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _label(context, 'WHAT STOOD OUT (OPTIONAL)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in kReviewTags)
                      _ChoicePill(
                        label: t,
                        selected: _tags.contains(t),
                        onTap: () => setState(() {
                          if (!_tags.add(t)) _tags.remove(t);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentController,
                  maxLength: 280,
                  maxLines: 3,
                  minLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Add a short comment (optional)',
                  ),
                ),
                if (lowRatingWithComment && _rating != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: Text(
                      'Reviews of 1 or 2 stars with a comment are also shown to campus admins.',
                      style: TextStyle(fontSize: 12, height: 1.35, color: p.textDim),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.readable(
                            AppColors.error, Theme.of(context).brightness),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Skip',
                        style: TextStyle(color: p.textDim, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Send review',
                        icon: CupertinoIcons.paperplane_fill,
                        height: 48,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                        variant: ButtonVariant.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.monoFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.palette.textFaint,
      ),
    );
  }
}

/// "How did it go?" card shown on a resolved case in My Activity.
/// Hides itself once the viewer has reviewed the case.
class ReviewPromptCard extends StatefulWidget {
  final String caseId;
  final String viewerId;
  final String aboutUserId;
  final String aboutName;

  const ReviewPromptCard({
    super.key,
    required this.caseId,
    required this.viewerId,
    required this.aboutUserId,
    required this.aboutName,
  });

  @override
  State<ReviewPromptCard> createState() => _ReviewPromptCardState();
}

class _ReviewPromptCardState extends State<ReviewPromptCard> {
  bool? _reviewed; // null while loading

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant ReviewPromptCard old) {
    super.didUpdateWidget(old);
    if (old.caseId != widget.caseId || old.viewerId != widget.viewerId) {
      _reviewed = null;
      _check();
    }
  }

  Future<void> _check() async {
    final done = await context
        .read<ReviewsProvider>()
        .hasReviewed(widget.caseId, viewerId: widget.viewerId);
    if (mounted) setState(() => _reviewed = done);
  }

  Future<void> _open() async {
    final submitted = await ReviewSheet.show(
      context,
      caseId: widget.caseId,
      viewerId: widget.viewerId,
      aboutUserId: widget.aboutUserId,
      aboutName: widget.aboutName,
    );
    if (submitted && mounted) setState(() => _reviewed = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.isDark ? AppColors.rose : AppColors.roseInk;

    if (_reviewed == null) return const SizedBox.shrink();

    if (_reviewed == true) {
      return Row(
        children: [
          Icon(CupertinoIcons.checkmark_seal_fill, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            'REVIEW SENT. THANK YOU.',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: p.textDim,
            ),
          ),
        ],
      );
    }

    final firstName = widget.aboutName.trim().split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW DID IT GO?',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Leave a quick review for $firstName.',
            style: TextStyle(fontSize: 13, color: p.textDim, height: 1.35),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Leave a review',
            icon: CupertinoIcons.star_fill,
            height: 40,
            onPressed: _open,
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
