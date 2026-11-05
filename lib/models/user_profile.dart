class UserProfile {
  final String username;
  final String phone;
  final String address;
  final List<String> favoriteProductIds;

  const UserProfile({
    required this.username,
    this.phone = '',
    this.address = '',
    this.favoriteProductIds = const [],
  });

  UserProfile copyWith({
    String? username,
    String? phone,
    String? address,
    List<String>? favoriteProductIds,
  }) {
    return UserProfile(
      username: username ?? this.username,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': phone,
      'address': address,
      'favoriteProductIds': favoriteProductIds,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? 'Customer',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      favoriteProductIds: (json['favoriteProductIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
