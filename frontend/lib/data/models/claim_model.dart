// lib/data/models/claim_model.dart

class ClaimModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemCategory;
  final String claimantId;
  final String claimantName;
  final int claimantTrustScore;
  final List<String> answers;
  final List<String> finderAnswers; // Stored for admin & finder comparison
  final int matchScore; // 0 - 100 (Visible to finder & admin, NEVER to claimant)
  final String status; // 'awaiting_admin' | 'passed_to_finder' | 'approved' | 'rejected' | 'rejected_fake' | 'handover_pending' | 'resolved'
  final String? rejectionReason;
  final String? handoverOtp; // 6-digit code for high value items, visible ONLY to claimant
  final bool isHighValue;
  final DateTime createdAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemCategory,
    required this.claimantId,
    required this.claimantName,
    required this.claimantTrustScore,
    required this.answers,
    this.finderAnswers = const [],
    this.matchScore = 0,
    this.status = 'awaiting_admin',
    this.rejectionReason,
    this.handoverOtp,
    this.isHighValue = false,
    required this.createdAt,
  });

  bool get isAwaitingAdmin => status == 'awaiting_admin';
  bool get isPassedToFinder => status == 'passed_to_finder';
  bool get isApproved => status == 'approved';
  bool get isHandoverPending => status == 'handover_pending';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';
  bool get isRejectedFake => status == 'rejected_fake';

  String get matchStrength {
    if (matchScore >= 80) return 'Strong match';
    if (matchScore >= 55) return 'Moderate match';
    return 'Partial match';
  }

  String get claimantTrustLabel {
    if (claimantTrustScore >= 80) return 'Trusted';
    if (claimantTrustScore >= 50) return 'Building trust';
    return 'New account';
  }

  ClaimModel copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemCategory,
    String? claimantId,
    String? claimantName,
    int? claimantTrustScore,
    List<String>? answers,
    List<String>? finderAnswers,
    int? matchScore,
    String? status,
    String? rejectionReason,
    String? handoverOtp,
    bool? isHighValue,
    DateTime? createdAt,
    bool clearHandoverOtp = false,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemCategory: itemCategory ?? this.itemCategory,
      claimantId: claimantId ?? this.claimantId,
      claimantName: claimantName ?? this.claimantName,
      claimantTrustScore: claimantTrustScore ?? this.claimantTrustScore,
      answers: answers ?? this.answers,
      finderAnswers: finderAnswers ?? this.finderAnswers,
      matchScore: matchScore ?? this.matchScore,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      handoverOtp: clearHandoverOtp ? null : (handoverOtp ?? this.handoverOtp),
      isHighValue: isHighValue ?? this.isHighValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemTitle: json['itemTitle'] as String? ?? 'Item',
      itemCategory: json['itemCategory'] as String? ?? 'Other',
      claimantId: json['claimantId'] as String,
      claimantName: json['claimantName'] as String,
      claimantTrustScore: (json['claimantTrustScore'] as num?)?.toInt() ?? 50,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      finderAnswers: (json['finderAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'awaiting_admin',
      rejectionReason: json['rejectionReason'] as String?,
      handoverOtp: json['handoverOtp'] as String?,
      isHighValue: json['isHighValue'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemCategory': itemCategory,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'claimantTrustScore': claimantTrustScore,
      'answers': answers,
      'finderAnswers': finderAnswers,
      'matchScore': matchScore,
      'status': status,
      'rejectionReason': rejectionReason,
      'handoverOtp': handoverOtp,
      'isHighValue': isHighValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
