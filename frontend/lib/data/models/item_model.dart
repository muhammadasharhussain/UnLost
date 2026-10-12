// lib/data/models/item_model.dart

class ItemModel {
  final String id;
  final String type; // 'found' | 'lost'
  final String title;
  final String category;
  final String description;
  final String area;
  final DateTime dateTime;
  final List<String> hiddenFields; // Private answers for found verification
  final String status; // 'pending_review' | 'active' | 'claim_pending' | 'handover_pending' | 'resolved' | 'rejected'
  final String? rejectionReason;
  final String posterId;
  final String posterName;
  final int posterTrustScore;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.area,
    required this.dateTime,
    this.hiddenFields = const [],
    this.status = 'pending_review',
    this.rejectionReason,
    required this.posterId,
    required this.posterName,
    required this.posterTrustScore,
    required this.createdAt,
  });

  bool get isFound => type == 'found';
  bool get isLost => type == 'lost';
  bool get isPendingReview => status == 'pending_review';
  bool get isActive => status == 'active';
  bool get isClaimPending => status == 'claim_pending';
  bool get isHandoverPending => status == 'handover_pending';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';

  String get posterTrustLabel {
    if (posterTrustScore >= 80) return 'Trusted';
    if (posterTrustScore >= 50) return 'Building trust';
    return 'New account';
  }

  ItemModel copyWith({
    String? id,
    String? type,
    String? title,
    String? category,
    String? description,
    String? area,
    DateTime? dateTime,
    List<String>? hiddenFields,
    String? status,
    String? rejectionReason,
    String? posterId,
    String? posterName,
    int? posterTrustScore,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      area: area ?? this.area,
      dateTime: dateTime ?? this.dateTime,
      hiddenFields: hiddenFields ?? this.hiddenFields,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      posterId: posterId ?? this.posterId,
      posterName: posterName ?? this.posterName,
      posterTrustScore: posterTrustScore ?? this.posterTrustScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      area: json['area'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      hiddenFields: (json['hiddenFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'pending_review',
      rejectionReason: json['rejectionReason'] as String?,
      posterId: json['posterId'] as String,
      posterName: json['posterName'] as String,
      posterTrustScore: (json['posterTrustScore'] as num?)?.toInt() ?? 50,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'category': category,
      'description': description,
      'area': area,
      'dateTime': dateTime.toIso8601String(),
      'hiddenFields': hiddenFields,
      'status': status,
      'rejectionReason': rejectionReason,
      'posterId': posterId,
      'posterName': posterName,
      'posterTrustScore': posterTrustScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
