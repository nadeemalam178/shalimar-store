class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role; // 'customer' or 'owner'
  final String provider; // 'password' or 'google.com'
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String appVersion;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.role = 'customer',
    this.provider = 'password',
    required this.createdAt,
    required this.lastLoginAt,
    this.appVersion = 'v3.2.0',
  });

  bool get isOwner => role == 'owner';

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    String? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? appVersion,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'appVersion': appVersion,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? uid}) {
    return UserModel(
      uid: uid ?? json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      provider: json['provider'] as String? ?? 'password',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      appVersion: json['appVersion'] as String? ?? 'v3.2.0',
    );
  }
}

