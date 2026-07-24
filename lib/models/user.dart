import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
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

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

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

@JsonSerializable()
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
