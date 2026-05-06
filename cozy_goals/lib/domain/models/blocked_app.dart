const Object _unsetBlockedDate = Object();

class BlockedApp {
  const BlockedApp({
    required this.id,
    required this.name,
    required this.target,
    this.kind = 'app',
    this.unlockedUntil,
  });

  final String id;
  final String name;

  /// Either `app` for a Linux process/command pattern or `site` for a domain.
  final String kind;

  /// App process pattern (`firefox`, `steam`) or website domain (`youtube.com`).
  final String target;

  final DateTime? unlockedUntil;

  bool get isUnlocked => unlockedUntil != null && unlockedUntil!.isAfter(DateTime.now());
  bool get isApp => kind == 'app';
  bool get isSite => kind == 'site';

  /// Kept as a compatibility alias for older UI/code.
  String get command => target;

  BlockedApp copyWith({
    String? name,
    String? kind,
    String? target,
    Object? unlockedUntil = _unsetBlockedDate,
  }) =>
      BlockedApp(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        target: target ?? this.target,
        unlockedUntil: identical(unlockedUntil, _unsetBlockedDate) ? this.unlockedUntil : unlockedUntil as DateTime?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'command': target,
        'kind': kind,
        'target': target,
        'unlockedUntil': unlockedUntil?.toIso8601String(),
      };

  factory BlockedApp.fromMap(Map<String, Object?> map) => BlockedApp(
        id: map['id'] as String,
        name: map['name'] as String,
        kind: map['kind'] as String? ?? 'app',
        target: map['target'] as String? ?? map['command'] as String? ?? '',
        unlockedUntil: map['unlockedUntil'] == null ? null : DateTime.parse(map['unlockedUntil'] as String),
      );
}
