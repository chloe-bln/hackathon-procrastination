class BlockedApp {
  const BlockedApp({
    required this.id,
    required this.name,
    required this.command,
    this.unlockedUntil,
  });

  final String id;
  final String name;
  final String command;
  final DateTime? unlockedUntil;

  bool get isUnlocked => unlockedUntil != null && unlockedUntil!.isAfter(DateTime.now());

  BlockedApp copyWith({String? name, String? command, DateTime? unlockedUntil}) => BlockedApp(
        id: id,
        name: name ?? this.name,
        command: command ?? this.command,
        unlockedUntil: unlockedUntil,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'command': command,
        'unlockedUntil': unlockedUntil?.toIso8601String(),
      };

  factory BlockedApp.fromMap(Map<String, Object?> map) => BlockedApp(
        id: map['id'] as String,
        name: map['name'] as String,
        command: map['command'] as String,
        unlockedUntil: map['unlockedUntil'] == null ? null : DateTime.parse(map['unlockedUntil'] as String),
      );
}
