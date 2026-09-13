/// A user-defined tag for grouping clients (e.g. "\u0628اش\u06af", "\u0627نھاین").
class Tag {
  final int? id;
  final String emoji;
  final String name;

  const Tag({
    this.id,
    required this.emoji,
    required this.name,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'emoji': emoji,
        'name': name,
      };

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
        id: map['id'] as int?,
        emoji: map['emoji'] as String,
        name: map['name'] as String,
      );

  Tag copyWith({int? id, String? emoji, String? name}) => Tag(
        id: id ?? this.id,
        emoji: emoji ?? this.emoji,
        name: name ?? this.name,
      );
}