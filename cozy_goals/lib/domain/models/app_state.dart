const Object _unset = Object();

class CozyAppState {
  const CozyAppState({
    required this.currentStreak,
    required this.longestStreak,
    required this.xp,
    required this.level,
    required this.freezeCount,
    required this.lastValidatedDate,
    this.lastStreakAwardedDate,
    this.avatarHair = 'hair_bun_mint',
    this.avatarClothes = 'clothes_lavender',
    this.avatarSkin = 'skin_peach',
    this.dayOffsetDays = 0,
  });

  final int currentStreak;
  final int longestStreak;
  final int xp;
  final int level;
  final int freezeCount;
  final String lastValidatedDate;
  final String? lastStreakAwardedDate;
  final String avatarHair;
  final String avatarClothes;
  final String avatarSkin;
  final int dayOffsetDays;

  CozyAppState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? xp,
    int? level,
    int? freezeCount,
    String? lastValidatedDate,
    Object? lastStreakAwardedDate = _unset,
    String? avatarHair,
    String? avatarClothes,
    String? avatarSkin,
    int? dayOffsetDays,
  }) =>
      CozyAppState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        freezeCount: freezeCount ?? this.freezeCount,
        lastValidatedDate: lastValidatedDate ?? this.lastValidatedDate,
        lastStreakAwardedDate: identical(lastStreakAwardedDate, _unset) ? this.lastStreakAwardedDate : lastStreakAwardedDate as String?,
        avatarHair: avatarHair ?? this.avatarHair,
        avatarClothes: avatarClothes ?? this.avatarClothes,
        avatarSkin: avatarSkin ?? this.avatarSkin,
        dayOffsetDays: dayOffsetDays ?? this.dayOffsetDays,
      );

  Map<String, Object?> toMap() => {
        'id': 1,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'xp': xp,
        'level': level,
        'freezeCount': freezeCount,
        'lastValidatedDate': lastValidatedDate,
        'lastStreakAwardedDate': lastStreakAwardedDate,
        'avatarHair': avatarHair,
        'avatarClothes': avatarClothes,
        'avatarSkin': avatarSkin,
        'dayOffsetDays': dayOffsetDays,
      };

  factory CozyAppState.fromMap(Map<String, Object?> map) => CozyAppState(
        currentStreak: map['currentStreak'] as int,
        longestStreak: map['longestStreak'] as int,
        xp: map['xp'] as int,
        level: map['level'] as int,
        freezeCount: map['freezeCount'] as int,
        lastValidatedDate: map['lastValidatedDate'] as String,
        lastStreakAwardedDate: map['lastStreakAwardedDate'] as String?,
        avatarHair: map['avatarHair'] as String? ?? 'hair_bun_mint',
        avatarClothes: map['avatarClothes'] as String? ?? 'clothes_lavender',
        avatarSkin: map['avatarSkin'] as String? ?? 'skin_peach',
        dayOffsetDays: (map['dayOffsetDays'] as int?) ?? 0,
      );
}
