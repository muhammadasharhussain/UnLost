// lib/core/review_logic.dart
// Pure Dart (no Flutter): decides who reviews whom once a case is closed.
import '../data/models/claim_model.dart';
import '../data/models/item_model.dart';

const List<String> kReviewOutcomes = [
  'Got my item back',
  'Partly',
  'Did not get it',
];

const List<String> kReviewTags = [
  'Honest',
  'On time',
  'Polite',
  'Easy to reach',
];

class ReviewTarget {
  final String caseId;
  final String aboutUserId;
  final String aboutName;

  const ReviewTarget({
    required this.caseId,
    required this.aboutUserId,
    required this.aboutName,
  });
}

/// The claim that actually closed the case: resolved first, otherwise the
/// approved one (non high-value items skip the handover code).
ClaimModel? winningClaim(List<ClaimModel> claims) {
  for (final c in claims) {
    if (c.status == 'resolved') return c;
  }
  for (final c in claims) {
    if (c.status == 'approved' || c.status == 'handover_pending') return c;
  }
  return null;
}

/// Who the viewer should review for this item + claim, or null when the
/// viewer was not part of the case (or the case is not resolved).
ReviewTarget? reviewTargetFor({
  required ItemModel item,
  required ClaimModel claim,
  required String viewerId,
}) {
  if (!item.isResolved) return null;
  if (viewerId.isEmpty) return null;

  if (viewerId == item.posterId && viewerId != claim.claimantId) {
    return ReviewTarget(
      caseId: item.id,
      aboutUserId: claim.claimantId,
      aboutName: claim.claimantName,
    );
  }
  if (viewerId == claim.claimantId && viewerId != item.posterId) {
    return ReviewTarget(
      caseId: item.id,
      aboutUserId: item.posterId,
      aboutName: item.posterName,
    );
  }
  return null;
}

/// Whether a review should be surfaced to admins: 1 or 2 stars with a comment.
bool isFlaggedRating(int rating, String comment) =>
    rating <= 2 && comment.trim().isNotEmpty;
