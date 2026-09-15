/// A user-defined tag for grouping clients (e.g. "\u0628اش\u06af", "\u0627نھاین").
class Tag {
  final int? id;
  final String name;

  const Tag({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
        id: map['id'] as int?,
        name: map['name'] as String,
      );

  Tag copyWith({int? id, String? name}) => Tag(
        id: id ?? this.id,
        name: name ?? this.name,
      );
}