class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? location;
  final DateTime createdAt;
  final bool emailVerified;
  final bool mfaEnabled; // NEW
  final String mfaMethod; // NEW - 'email' for now

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.location,
    required this.createdAt,
    this.emailVerified = false,
    this.mfaEnabled = false, // NEW
    this.mfaMethod = 'email', // NEW
  });

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
      mfaEnabled: json['mfaEnabled'] ?? false, // NEW
      mfaMethod: json['mfaMethod'] ?? 'email', // NEW
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
      'mfaEnabled': mfaEnabled, // NEW
      'mfaMethod': mfaMethod, // NEW
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
    bool? mfaEnabled, // NEW
    String? mfaMethod, // NEW
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
      mfaEnabled: mfaEnabled ?? this.mfaEnabled, // NEW
      mfaMethod: mfaMethod ?? this.mfaMethod, // NEW
    );
  }
}