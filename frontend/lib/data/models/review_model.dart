// lib/data/models/review_model.dart

class ReviewModel {
  final String id;
  final String caseId;
  final String itemCategory; // public-safe: category only, never item details
  final String authorId;
  final String authorName;
  final String aboutUserId;
  final String aboutName; // shown to admins only
  final int rating; // 1 to 5
  final String outcome; // "Got my item back" / "Partly" / "Did not get it"
  final List<String> tags; // e.g. "Honest", "On time", "Polite", "Easy to reach"
  final String comment; // up to 280 chars
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.caseId,
    this.itemCategory = 'other',
    required this.authorId,
    required this.authorName,
    required this.aboutUserId,
    this.aboutName = '',
    required this.rating,
    required this.outcome,
    this.tags = const [],
    this.comment = '',
    required this.createdAt,
  });

  bool get isFlaggedForAdmin => rating <= 2 && comment.trim().isNotEmpty;

  /// Anonymised public name: first name plus last initial ("Terry M.").
  String get publicName {
    final parts = authorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Student';
    if (parts.length == 1) return parts.first;
    final last = parts.last;
    if (last.endsWith('.')) return '${parts.first} $last';
    return '${parts.first} ${last[0].toUpperCase()}.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'itemCategory': itemCategory,
        'authorId': authorId,
        'authorName': authorName,
        'aboutUserId': aboutUserId,
        'aboutName': aboutName,
        'rating': rating,
        'outcome': outcome,
        'tags': tags,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        caseId: json['caseId'] as String,
        itemCategory: (json['itemCategory'] as String?) ?? 'other',
        authorId: json['authorId'] as String,
        authorName: (json['authorName'] as String?) ?? 'Student',
        aboutUserId: json['aboutUserId'] as String,
        aboutName: (json['aboutName'] as String?) ?? '',
        rating: (json['rating'] as num).toInt(),
        outcome: json['outcome'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        comment: (json['comment'] as String?) ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
