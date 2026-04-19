class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final String? bio;
  final String? createdAt;
  final String? updatedAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Be defensive: json['id'] or json['uid'] may be missing or not a String.
    // Convert to string when present, otherwise use empty string (or throw if you prefer strict validation).
    final rawId = json['id'] ?? json['uid'];
    final id = rawId?.toString() ?? '';

    return AppUser(
      id: id,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? avatarUrl,
    String? bio,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': id,
      'email': email,
      'displayName': displayName,
      'role': role,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

