class User {
  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  /// Maps to users.city in the current schema.
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

  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?)?.trim() ?? '';
    final lastName = (json['last_name'] as String?)?.trim() ?? '';
    final username = (json['username'] as String?)?.trim();
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');

    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: fullName.isNotEmpty
          ? fullName
          : (username?.isNotEmpty == true ? username : null),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['city'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: 0,
      productsCount: (json['total_products'] as num?)?.toInt() ?? 0,
      followersCount: (json['total_followers'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isPhoneVerified: json['phone_verified'] as bool? ?? false,
      preferredLanguage: json['language_preference'] as String? ??
          json['language'] as String? ??
          'ar',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  /// Fields that a member may edit on their own users row.
  /// Never sends role, account status, verification, balances, or identifiers.
  Map<String, dynamic> toJson() {
    final nameParts = (displayName ?? '').trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty || nameParts.first.isEmpty
        ? null
        : nameParts.first;
    final lastName =
        nameParts.length > 1 ? nameParts.skip(1).join(' ') : null;

    return {
      if (firstName != null) 'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'city': location,
      'language_preference': preferredLanguage,
      'notifications_enabled': notificationsEnabled,
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
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
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
  final String? phone;

  UserProfile({
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.location,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?) ?? '';
    final lastName = (json['last_name'] as String?) ?? '';
    return UserProfile(
      userId: json['id'] as String,
      displayName: [firstName, lastName].where((s) => s.isNotEmpty).join(' '),
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      location: json['city'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+'));
    return {
      if (parts.isNotEmpty && parts.first.isNotEmpty) 'first_name': parts.first,
      'last_name': parts.length > 1 ? parts.skip(1).join(' ') : null,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (location != null) 'city': location,
      if (phone != null) 'phone': phone,
    };
  }
}
