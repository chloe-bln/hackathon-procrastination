class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.goalDate,
    this.description,
    this.durationMinutes = 25,
    this.focusSeconds = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String goalDate;
  final int durationMinutes;
  final int focusSeconds;
  final bool isCompleted;
  final DateTime? completedAt;

  Goal copyWith({
    String? title,
    String? description,
    int? durationMinutes,
    int? focusSeconds,
    bool? isCompleted,
    DateTime? completedAt,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        goalDate: goalDate,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        focusSeconds: focusSeconds ?? this.focusSeconds,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'goalDate': goalDate,
        'durationMinutes': durationMinutes,
        'focusSeconds': focusSeconds,
        'isCompleted': isCompleted ? 1 : 0,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Goal.fromMap(Map<String, Object?> map) => Goal(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        goalDate: map['goalDate'] as String,
        durationMinutes: (map['durationMinutes'] as int?) ?? 25,
        focusSeconds: (map['focusSeconds'] as int?) ?? 0,
        isCompleted: (map['isCompleted'] as int) == 1,
        completedAt: map['completedAt'] == null ? null : DateTime.parse(map['completedAt'] as String),
      );
}
