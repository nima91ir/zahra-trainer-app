/// A trainer's client.
class Client {
  final int? id;
  final String name;
  final String? contact;
  final List<int> tagIds;
  final String note;
  final int bonusSessions;

  const Client({
    this.id,
    required this.name,
    this.contact,
    this.tagIds = const [],
    this.note = '',
    this.bonusSessions = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'tagIds': tagIds,
        'note': note,
        'bonusSessions': bonusSessions,
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as int?,
        name: map['name'] as String,
        contact: map['contact'] as String?,
        tagIds: (map['tagIds'] as List?)?.cast<int>() ?? const [],
        note: (map['note'] as String?) ?? '',
        bonusSessions: (map['bonusSessions'] as int?) ?? 0,
      );

  Client copyWith({
    int? id,
    String? name,
    String? contact,
    List<int>? tagIds,
    String? note,
    int? bonusSessions,
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        contact: contact ?? this.contact,
        tagIds: tagIds ?? this.tagIds,
        note: note ?? this.note,
        bonusSessions: bonusSessions ?? this.bonusSessions,
      );

  static const Client empty = Client(name: '');
}