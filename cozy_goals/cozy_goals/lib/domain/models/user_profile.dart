class UserProfile {
  const UserProfile({
    required this.username,
    required this.birthDate,
  });

  final String username;
  final DateTime birthDate;

  Map<String, Object?> toMap() => {
        'id': 1,
        'username': username,
        'birthDate': birthDate.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        username: map['username'] as String,
        birthDate: DateTime.parse(map['birthDate'] as String),
      );
}
