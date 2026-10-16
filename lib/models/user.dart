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
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final List<String>? favorites;

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
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.preferredLanguage = 'ar',
    this.notificationsEnabled = true,
    this.favorites,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      productsCount: json['productsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
      preferredLanguage: json['preferredLanguage'] as String? ?? 'ar',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      favorites: (json['favorites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalReviews': totalReviews,
      'productsCount': productsCount,
      'followersCount': followersCount,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'preferredLanguage': preferredLanguage,
      'notificationsEnabled': notificationsEnabled,
      'favorites': favorites,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    String? preferredLanguage,
    bool? notificationsEnabled,
    List<String>? favorites,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      favorites: favorites ?? this.favorites,
    );
  }
}

class UserProfile {
  final String userId;
  final String displayName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
