// lib/ui/claims/finder_claim_confirm_card.dart
// Owner side of the lost-report flow: a finder (already passed by admin) says
// "I found this". The owner answers "This is mine" or "Not mine".
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/models/claim_model.dart';
import '../../features/reviews/review_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/reviews_provider.dart';

class FinderClaimConfirmCard extends StatefulWidget {
  final ClaimModel claim;

  /// Called after the owner's answer was stored. The HOST screen reloads its
  /// lists and opens the review sheet, because this card disappears (or is
  /// rebuilt) as soon as the claim changes state.
  final Future<void> Function(ClaimModel claim, bool isMine)? onAnswered;

  const FinderClaimConfirmCard({
    super.key,
    required this.claim,
    this.onAnswered,
  });

  @override
  State<FinderClaimConfirmCard> createState() => _FinderClaimConfirmCardState();
}

class _FinderClaimConfirmCardState extends State<FinderClaimConfirmCard> {
  bool _busy = false;

  Future<void> _answer(bool isMine) async {
    if (_busy) return;

    if (isMine) {
      final ok = await _confirmDialog();
      if (ok != true || !mounted) return;
    }

    setState(() => _busy = true);

    final claimsProv = context.read<ClaimsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final claim = widget.claim;
    final onAnswered = widget.onAnswered;

    final ok = await claimsProv.confirmFinderClaim(
      claimId: claim.id,
      isMine: isMine,
    );

    if (mounted) setState(() => _busy = false);

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(claimsProv.errorMessage ?? 'Could not save your answer.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(isMine
            ? 'Great. The case is closed. Arrange pickup with the finder.'
            : 'Got it. This finder was marked as not yours.'),
      ),
    );

    if (onAnswered != null) await onAnswered(claim, isMine);
  }

  Future<bool?> _confirmDialog() {
    final p = context.palette;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Is this your item?',
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w700,
            color: p.text,
          ),
        ),
        content: Text(
          'Only say yes if the description really matches what you lost. '
          'This closes your report.',
          style: TextStyle(fontSize: 14, height: 1.4, color: p.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: p.textDim)),
          ),
          CustomButton(
            text: 'Yes, this is mine',
            width: 170,
            height: 44,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.isDark ? AppColors.cerulean : AppColors.ceruleanInk;
    final claim = widget.claim;
    final description =
        claim.answers.isNotEmpty ? claim.answers.first.trim() : '';
    final open = claim.status == 'passed_to_finder';

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
          Row(
            children: [
              Icon(CupertinoIcons.hand_raised_fill, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${claim.claimantName.split(' ').first.toUpperCase()} SAYS: I FOUND THIS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Checked and passed by an admin.',
            style: TextStyle(fontSize: 12, color: p.textFaint),
          ),
          const SizedBox(height: 8),
          Text(
            description.isEmpty ? 'No description given.' : description,
            style: TextStyle(fontSize: 14, height: 1.4, color: p.text),
          ),
          if (open) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'This is mine',
                    icon: CupertinoIcons.checkmark_alt,
                    height: 44,
                    isLoading: _busy,
                    onPressed: _busy ? null : () => _answer(true),
                    variant: ButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: 'Not mine',
                    height: 44,
                    onPressed: _busy ? null : () => _answer(false),
                    variant: ButtonVariant.secondary,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              claim.status == 'rejected'
                  ? 'MARKED AS NOT YOURS'
                  : 'CONFIRMED AS YOURS',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: p.textDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// Run by the HOST screen (My Activity, Item detail) after the owner answered.
/// Reloads lists, then, when the owner said "This is mine", asks them to
/// review the finder. Safe to call from a screen that stays mounted.
Future<void> afterFinderClaimAnswered(
  BuildContext host,
  ClaimModel claim,
  bool isMine,
) async {
  final itemsProv = host.read<ItemsProvider>();
  final reviewsProv = host.read<ReviewsProvider>();
  final viewerId = host.read<AuthProvider>().currentUser?.id ?? '';

  await itemsProv.loadMyItems();
  itemsProv.loadItems();
  reviewsProv.loadReunions();

  if (!isMine || viewerId.isEmpty || !host.mounted) return;

  final already = await reviewsProv.hasReviewed(claim.itemId, viewerId: viewerId);
  if (already || !host.mounted) return;

  await ReviewSheet.show(
    host,
    caseId: claim.itemId,
    viewerId: viewerId,
    aboutUserId: claim.claimantId,
    aboutName: claim.claimantName,
  );
}
