class User {
  final String id;

  final String name;
  final String initials;
  final String city;

  final String bio;

  final double rating;
  final int reviewCount;
  final int completedSwaps;
  final int responseRate;

  final String memberSince;

  final String availability;
  final String language;
  final String preferredMode;
  final String teachingStyle;

  final bool emailVerified;
  final bool profileCompleted;

  const User({
    required this.id,
    required this.name,
    required this.initials,
    required this.city,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.completedSwaps,
    required this.responseRate,
    required this.memberSince,
    required this.availability,
    required this.language,
    required this.preferredMode,
    required this.teachingStyle,
    required this.emailVerified,
    required this.profileCompleted,
  });

  User copyWith({
    String? id,
    String? name,
    String? initials,
    String? city,
    String? bio,
    double? rating,
    int? reviewCount,
    int? completedSwaps,
    int? responseRate,
    String? memberSince,
    String? availability,
    String? language,
    String? preferredMode,
    String? teachingStyle,
    bool? emailVerified,
    bool? profileCompleted,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedSwaps:
      completedSwaps ?? this.completedSwaps,
      responseRate:
      responseRate ?? this.responseRate,
      memberSince:
      memberSince ?? this.memberSince,
      availability:
      availability ?? this.availability,
      language:
      language ?? this.language,
      preferredMode:
      preferredMode ?? this.preferredMode,
      teachingStyle:
      teachingStyle ?? this.teachingStyle,
      emailVerified:
      emailVerified ?? this.emailVerified,
      profileCompleted:
      profileCompleted ?? this.profileCompleted,
    );
  }
}