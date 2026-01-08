class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? location;
  final DateTime createdAt;
  final bool emailVerified;
  final bool mfaEnabled;
  final String mfaMethod;
  final double ratingSum; // NEW
  final int reviewCount; // NEW

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.location,
    required this.createdAt,
    this.emailVerified = false,
    this.mfaEnabled = false,
    this.mfaMethod = 'email',
    this.ratingSum = 0.0, // NEW
    this.reviewCount = 0, // NEW
  });

  double get averageRating => reviewCount == 0 ? 0 : ratingSum / reviewCount;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      phone: json['phone'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      emailVerified: json['emailVerified'] ?? false,
      mfaEnabled: json['mfaEnabled'] ?? false,
      mfaMethod: json['mfaMethod'] ?? 'email',
      ratingSum: (json['ratingSum'] ?? 0).toDouble(), // NEW
      reviewCount: json['reviewCount'] ?? 0, // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'emailVerified': emailVerified,
      'mfaEnabled': mfaEnabled,
      'mfaMethod': mfaMethod,
      'ratingSum': ratingSum, // NEW
      'reviewCount': reviewCount, // NEW
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    String? location,
    DateTime? createdAt,
    bool? emailVerified,
    bool? mfaEnabled,
    String? mfaMethod,
    double? ratingSum, // NEW
    int? reviewCount, // NEW
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      mfaMethod: mfaMethod ?? this.mfaMethod,
      ratingSum: ratingSum ?? this.ratingSum,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
