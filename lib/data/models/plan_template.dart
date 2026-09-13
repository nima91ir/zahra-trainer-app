/// A reusable template for client plans (e.g. "\u0628ر\u0627\u0646\u0645\u0647 \u0627\u0644\u0632\u0627\u062a\u062e\u0627\u062a").
class PlanTemplate {
  final int? id;
  final String name;
  final int sessions;
  final int days;

  const PlanTemplate({
    this.id,
    required this.name,
    required this.sessions,
    required this.days,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sessions': sessions,
        'days': days,
      };

  factory PlanTemplate.fromMap(Map<String, dynamic> map) => PlanTemplate(
        id: map['id'] as int?,
        name: map['name'] as String,
        sessions: map['sessions'] as int,
        days: map['days'] as int,
      );

  PlanTemplate copyWith({
    int? id,
    String? name,
    int? sessions,
    int? days,
  }) =>
      PlanTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        sessions: sessions ?? this.sessions,
        days: days ?? this.days,
      );

  static const PlanTemplate empty =
      PlanTemplate(name: '', sessions: 0, days: 0);
}