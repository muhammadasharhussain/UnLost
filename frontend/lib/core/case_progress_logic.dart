// lib/core/case_progress_logic.dart
import '../data/models/item_model.dart';
import '../data/models/claim_model.dart';

enum StepState { done, current, pending, rejected }

class CaseProgressStep {
  final String label;
  final StepState state;

  const CaseProgressStep({
    required this.label,
    required this.state,
  });
}

class CaseProgress {
  final List<CaseProgressStep> steps;
  final String statusText;
  final bool isRejected;
  final String? rejectionReason;

  const CaseProgress({
    required this.steps,
    required this.statusText,
    this.isRejected = false,
    this.rejectionReason,
  });
}

/// Derives progression steps and descriptive status text for an item/claim context.
CaseProgress progressFor({
  required ItemModel item,
  List<ClaimModel> claims = const [],
  required String viewerId,
  required bool viewerIsAdmin,
  ClaimModel? claimContext,
}) {
  // If viewing a specific claim from the claimant's perspective
  if (claimContext != null && claimContext.claimantId == viewerId && !viewerIsAdmin) {
    return _claimantClaimProgress(item, claimContext);
  }

  // 1. Rejected post check
  if (item.isRejected) {
    return CaseProgress(
      steps: [
        const CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        const CaseProgressStep(label: 'REVIEW', state: StepState.rejected),
      ],
      statusText: item.rejectionReason ?? 'Post was rejected by campus administration',
      isRejected: true,
      rejectionReason: item.rejectionReason,
    );
  }

  // 2. Admin view
  if (viewerIsAdmin) {
    return _adminProgress(item, claims);
  }

  // 3. Finder's own post view
  if (item.isFound && item.posterId == viewerId) {
    return _finderPostProgress(item, claims);
  }

  // 4. Lost poster's own post view
  if (item.isLost && item.posterId == viewerId) {
    return _lostPostProgress(item, claims);
  }

  // 5. Public feed / other student view
  return _publicProgress(item, claims);
}

CaseProgress _claimantClaimProgress(ItemModel item, ClaimModel claim) {
  // Finder message on a LOST report:
  // Message -> Admin -> Owner confirmed -> Handover code -> Returned
  if (claim.isFinderClaim || item.isLost) {
    const labels = ['MESSAGE', 'ADMIN', 'OWNER', 'PICKUP CODE', 'RETURNED'];
    if (claim.isRejected || claim.isRejectedFake) {
      return const CaseProgress(
        steps: [
          CaseProgressStep(label: 'MESSAGE', state: StepState.done),
          CaseProgressStep(label: 'ADMIN', state: StepState.rejected),
        ],
        statusText: 'Finder message was rejected or marked as not theirs.',
        isRejected: true,
        rejectionReason: 'Owner or admin indicated item is not theirs.',
      );
    }

    int currentIdx = 0;
    String text = 'Message sent. Waiting for admin to review.';

    if (claim.isAwaitingAdmin) {
      currentIdx = 1;
      text = 'Waiting for admin to review your message.';
    } else if (claim.isPassedToFinder) {
      currentIdx = 2;
      text = 'Admin passed your message! Waiting for owner to confirm.';
    } else if (claim.isHandoverPending) {
      currentIdx = 3;
      text = 'Owner confirmed! Check your pickup code and meet the finder.';
    } else if (claim.isResolved) {
      currentIdx = labels.length;
      text = 'Item returned. Case closed!';
    }

    final steps = List.generate(labels.length, (i) {
      if (i < currentIdx) return CaseProgressStep(label: labels[i], state: StepState.done);
      if (i == currentIdx) return CaseProgressStep(label: labels[i], state: StepState.current);
      return CaseProgressStep(label: labels[i], state: StepState.pending);
    });

    return CaseProgress(steps: steps, statusText: text);
  }

  // Found post claim flow: Sent -> Admin -> Finder approved -> Pickup code -> Returned
  // OTP CODE step is always present (not only for high-value items).
  const labels = ['SENT', 'ADMIN', 'FINDER', 'PICKUP CODE', 'RETURNED'];

  if (claim.isRejected || claim.isRejectedFake) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SENT', state: StepState.done),
        CaseProgressStep(label: 'ADMIN', state: StepState.rejected),
      ],
      statusText: 'Claim was rejected',
      isRejected: true,
      rejectionReason: 'Claim answers did not verify ownership.',
    );
  }

  int currentIdx = 0;
  String text = 'Claim submitted. Waiting for admin review.';

  if (claim.isAwaitingAdmin) {
    currentIdx = 1;
    text = 'Waiting for admin to review your claim.';
  } else if (claim.isPassedToFinder) {
    currentIdx = 2;
    text = 'Admin passed claim. Waiting for finder to approve.';
  } else if (claim.isHandoverPending) {
    // Step 3 = PICKUP CODE — claimant shows the code to the finder.
    currentIdx = 3;
    text = 'Approved! Show your 6-digit pickup code to the finder.';
  } else if (claim.isResolved) {
    currentIdx = labels.length;
    text = 'Item returned. Case closed!';
  }

  final steps = List.generate(labels.length, (i) {
    if (i < currentIdx) return CaseProgressStep(label: labels[i], state: StepState.done);
    if (i == currentIdx) return CaseProgressStep(label: labels[i], state: StepState.current);
    return CaseProgressStep(label: labels[i], state: StepState.pending);
  });

  return CaseProgress(steps: steps, statusText: text);
}

CaseProgress _finderPostProgress(ItemModel item, List<ClaimModel> claims) {
  // 1 Submitted, 2 Admin approved, 3 Claim received, 4 Admin passed claim, 5 You approved, 6 Returned
  const labels = ['SUBMITTED', 'APPROVED', 'CLAIM', 'ADMIN OK', 'CONFIRMED', 'RETURNED'];

  if (item.isPendingReview) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'REVIEW', state: StepState.current),
        CaseProgressStep(label: 'CLAIM', state: StepState.pending),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.pending),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.pending),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Waiting for admin to review your found item post.',
    );
  }

  final activeClaims = claims.where((c) => !c.isRejected && !c.isRejectedFake).toList();
  final passedClaims = activeClaims.where((c) => c.status != 'awaiting_admin').toList();
  final approvedClaims = passedClaims.where((c) => c.status == 'approved' || c.status == 'handover_pending' || c.status == 'resolved').toList();

  int currentIdx = 1;
  String text = 'Post active. Waiting for claims.';

  if (item.isResolved) {
    currentIdx = 6;
    text = 'Item returned to owner. Case closed!';
  } else if (approvedClaims.isNotEmpty) {
    currentIdx = 5;
    text = 'You approved the claimant. Handover in progress.';
  } else if (passedClaims.isNotEmpty) {
    currentIdx = 4;
    text = 'Admin passed ${passedClaims.length} claim(s). Your turn to review.';
  } else if (activeClaims.isNotEmpty) {
    currentIdx = 3;
    text = '${activeClaims.length} claim(s) received. Waiting for admin review.';
  }

  final steps = List.generate(labels.length, (i) {
    if (i < currentIdx) return CaseProgressStep(label: labels[i], state: StepState.done);
    if (i == currentIdx) return CaseProgressStep(label: labels[i], state: StepState.current);
    return CaseProgressStep(label: labels[i], state: StepState.pending);
  });

  return CaseProgress(steps: steps, statusText: text);
}

CaseProgress _lostPostProgress(ItemModel item, List<ClaimModel> claims) {
  // 1 Submitted, 2 Admin approved, 3 Finder claim, 4 Admin approved finder claim, 5 You confirmed, 6 Returned


  if (item.isPendingReview) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'REVIEW', state: StepState.current),
        CaseProgressStep(label: 'FOUND HIT', state: StepState.pending),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.pending),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.pending),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Waiting for admin to review your lost item report.',
    );
  }

  if (item.isResolved) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'APPROVED', state: StepState.done),
        CaseProgressStep(label: 'FOUND HIT', state: StepState.done),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.done),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.done),
        CaseProgressStep(label: 'RETURNED', state: StepState.done),
      ],
      statusText: 'Item reunited! Case closed.',
    );
  }

  // A finder message the owner answered "Not mine" (or admin rejected) no
  // longer counts: the report goes back to "looking for matches".
  final finderClaims =
      claims.where((c) => !c.isRejected && !c.isRejectedFake).toList();
  if (finderClaims.isEmpty) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'APPROVED', state: StepState.current),
        CaseProgressStep(label: 'FOUND HIT', state: StepState.pending),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.pending),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.pending),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Looking for matching found items on campus.',
    );
  }

  final passedFinderClaims = finderClaims.where((c) => c.status != 'awaiting_admin' && !c.isRejected && !c.isRejectedFake).toList();
  if (passedFinderClaims.isEmpty) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'APPROVED', state: StepState.done),
        CaseProgressStep(label: 'FOUND HIT', state: StepState.current),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.pending),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.pending),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'A finder submitted a match! Admin reviewing.',
    );
  }

  final confirmedClaims = passedFinderClaims.where((c) => c.status == 'approved' || c.status == 'handover_pending' || c.status == 'resolved').toList();
  if (confirmedClaims.isNotEmpty) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
        CaseProgressStep(label: 'APPROVED', state: StepState.done),
        CaseProgressStep(label: 'FOUND HIT', state: StepState.done),
        CaseProgressStep(label: 'ADMIN OK', state: StepState.done),
        CaseProgressStep(label: 'CONFIRMED', state: StepState.current),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Confirmed! Coordinate handover with finder.',
    );
  }

  return const CaseProgress(
    steps: [
      CaseProgressStep(label: 'SUBMITTED', state: StepState.done),
      CaseProgressStep(label: 'APPROVED', state: StepState.done),
      CaseProgressStep(label: 'FOUND HIT', state: StepState.done),
      CaseProgressStep(label: 'ADMIN OK', state: StepState.current),
      CaseProgressStep(label: 'CONFIRMED', state: StepState.pending),
      CaseProgressStep(label: 'RETURNED', state: StepState.pending),
    ],
    statusText: 'Admin passed finder match. Check if this is yours!',
  );
}

CaseProgress _publicProgress(ItemModel item, List<ClaimModel> claims) {


  if (item.isResolved) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'POSTED', state: StepState.done),
        CaseProgressStep(label: 'OPEN', state: StepState.done),
        CaseProgressStep(label: 'REVIEW', state: StepState.done),
        CaseProgressStep(label: 'HANDOVER', state: StepState.done),
        CaseProgressStep(label: 'RETURNED', state: StepState.done),
      ],
      statusText: 'Resolved & Returned',
    );
  }

  if (item.isHandoverPending) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'POSTED', state: StepState.done),
        CaseProgressStep(label: 'OPEN', state: StepState.done),
        CaseProgressStep(label: 'REVIEW', state: StepState.done),
        CaseProgressStep(label: 'HANDOVER', state: StepState.current),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Handover in progress',
    );
  }

  if (item.isClaimPending || claims.any((c) => c.status == 'passed_to_finder')) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'POSTED', state: StepState.done),
        CaseProgressStep(label: 'OPEN', state: StepState.done),
        CaseProgressStep(label: 'REVIEW', state: StepState.current),
        CaseProgressStep(label: 'HANDOVER', state: StepState.pending),
        CaseProgressStep(label: 'RETURNED', state: StepState.pending),
      ],
      statusText: 'Claim under review',
    );
  }

  return const CaseProgress(
    steps: [
      CaseProgressStep(label: 'POSTED', state: StepState.done),
      CaseProgressStep(label: 'OPEN', state: StepState.current),
      CaseProgressStep(label: 'REVIEW', state: StepState.pending),
      CaseProgressStep(label: 'HANDOVER', state: StepState.pending),
      CaseProgressStep(label: 'RETURNED', state: StepState.pending),
    ],
    statusText: 'Open for verification',
  );
}

CaseProgress _adminProgress(ItemModel item, List<ClaimModel> claims) {


  if (item.isPendingReview) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'QUEUE', state: StepState.current),
        CaseProgressStep(label: 'POST OK', state: StepState.pending),
        CaseProgressStep(label: 'CLAIMS', state: StepState.pending),
        CaseProgressStep(label: 'RESOLVE', state: StepState.pending),
      ],
      statusText: 'Awaiting administrator verification & approval.',
    );
  }

  if (item.isResolved) {
    return const CaseProgress(
      steps: [
        CaseProgressStep(label: 'QUEUE', state: StepState.done),
        CaseProgressStep(label: 'POST OK', state: StepState.done),
        CaseProgressStep(label: 'CLAIMS', state: StepState.done),
        CaseProgressStep(label: 'RESOLVE', state: StepState.done),
      ],
      statusText: 'Case resolved and verified by campus administration.',
    );
  }

  final pendingClaims = claims.where((c) => c.status == 'awaiting_admin').toList();
  if (pendingClaims.isNotEmpty) {
    return CaseProgress(
      steps: const [
        CaseProgressStep(label: 'QUEUE', state: StepState.done),
        CaseProgressStep(label: 'POST OK', state: StepState.done),
        CaseProgressStep(label: 'CLAIMS', state: StepState.current),
        CaseProgressStep(label: 'RESOLVE', state: StepState.pending),
      ],
      statusText: '${pendingClaims.length} claim(s) waiting in admin review queue.',
    );
  }

  return const CaseProgress(
    steps: [
      CaseProgressStep(label: 'QUEUE', state: StepState.done),
      CaseProgressStep(label: 'POST OK', state: StepState.done),
      CaseProgressStep(label: 'CLAIMS', state: StepState.pending),
      CaseProgressStep(label: 'RESOLVE', state: StepState.pending),
    ],
    statusText: 'Post approved. Monitoring claim pipeline.',
  );
}
