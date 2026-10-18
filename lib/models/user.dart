class User {
  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int totalReviews;
  final int productsCount;
  final int followersCount;
  final bool isVerified;
  final bool isPhoneVerified;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.totalReviews = 0,
    this.productsCount = 0,
    this.followersCount = 0,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.preferredLanguage = 'ar',
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?, // ✅ FIXED: snake_case
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?, // ✅ FIXED: snake_case
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0, // ✅ FIXED: snake_case
      productsCount: json['products_count'] as int? ?? 0, // ✅ FIXED: snake_case
      followersCount: json['followers_count'] as int? ?? 0, // ✅ FIXED: snake_case
      isVerified: json['is_verified'] as bool? ?? false, // ✅ FIXED: snake_case
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false, // ✅ FIXED: snake_case
      preferredLanguage: json['preferred_language'] as String? ?? 'ar', // ✅ FIXED: snake_case
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true, // ✅ FIXED: snake_case
      createdAt: DateTime.parse(json['created_at'] as String), // ✅ FIXED: snake_case
      updatedAt: DateTime.parse(json['updated_at'] as String), // ✅ FIXED: snake_case
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String), // ✅ FIXED: snake_case
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName, // ✅ FIXED: snake_case
      'phone': phone,
      'avatar_url': avatarUrl, // ✅ FIXED: snake_case
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'total_reviews': totalReviews, // ✅ FIXED: snake_case
      'products_count': productsCount, // ✅ FIXED: snake_case
      'followers_count': followersCount, // ✅ FIXED: snake_case
      'is_verified': isVerified, // ✅ FIXED: snake_case
      'is_phone_verified': isPhoneVerified, // ✅ FIXED: snake_case
      'preferred_language': preferredLanguage, // ✅ FIXED: snake_case
      'notifications_enabled': notificationsEnabled, // ✅ FIXED: snake_case
      'created_at': createdAt.toIso8601String(), // ✅ FIXED: snake_case
      'updated_at': updatedAt.toIso8601String(), // ✅ FIXED: snake_case
      'last_seen_at': lastSeenAt?.toIso8601String(), // ✅ FIXED: snake_case
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalReviews,
    int? productsCount,
    int? followersCount,
    bool? isVerified,
    bool? isPhoneVerified,
    String? preferredLanguage,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      productsCount: productsCount ?? this.productsCount,
      followersCount: followersCount ?? this.followersCount,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class UserProfile {
  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? location;

  UserProfile({
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String, // ✅ FIXED: snake_case
      displayName: json['display_name'] as String?, // ✅ FIXED: snake_case
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?, // ✅ FIXED: snake_case
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId, // ✅ FIXED: snake_case
      'display_name': displayName, // ✅ FIXED: snake_case
      'bio': bio,
      'avatar_url': avatarUrl, // ✅ FIXED: snake_case
      'location': location,
    };
  }
}
