// lib/data/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'student' | 'admin'
  final int trustScore; // 0 - 100
  final int itemsReturned;
  final int itemsRecovered;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.trustScore,
    this.itemsReturned = 0,
    this.itemsRecovered = 0,
    this.token,
  });

  bool get isAdmin => role == 'admin';

  String get trustLabel {
    if (trustScore >= 80) return 'Trusted';
    if (trustScore >= 50) return 'Building trust';
    return 'New account';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    int? trustScore,
    int? itemsReturned,
    int? itemsRecovered,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      itemsReturned: itemsReturned ?? this.itemsReturned,
      itemsRecovered: itemsRecovered ?? this.itemsRecovered,
      token: token ?? this.token,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 50,
      itemsReturned: (json['itemsReturned'] as num?)?.toInt() ?? 0,
      itemsRecovered: (json['itemsRecovered'] as num?)?.toInt() ?? 0,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'trustScore': trustScore,
      'itemsReturned': itemsReturned,
      'itemsRecovered': itemsRecovered,
      'token': token,
    };
  }
}
