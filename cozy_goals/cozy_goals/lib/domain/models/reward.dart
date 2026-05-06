class Reward {
  const Reward({
    required this.id,
    required this.type,
    required this.label,
  });

  final String id;
  final String type; // hair, clothes, freeze
  final String label;

  Map<String, Object?> toMap({bool isUnlocked = true}) => {
        'id': id,
        'type': type,
        'label': label,
        'isUnlocked': isUnlocked ? 1 : 0,
      };

  factory Reward.fromMap(Map<String, Object?> map) => Reward(
        id: map['id'] as String,
        type: map['type'] as String,
        label: map['label'] as String,
      );
}
