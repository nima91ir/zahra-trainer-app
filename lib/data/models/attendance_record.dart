/// A single attendance mark for a client on a given Jalali date.
class AttendanceRecord {
  final int? id;
  final int clientId;
  final String date;   // Jalali string like '۱۴۰۵/۰۶/۲۱'
  final String status; // 'present' | 'absent'
  final int sessions;  // number of sessions for this date, default 1

  const AttendanceRecord({
    this.id,
    required this.clientId,
    required this.date,
    required this.status,
    this.sessions = 1,
  });

  AttendanceRecord copyWith({
    int? id,
    int? clientId,
    String? date,
    String? status,
    int? sessions,
  }) =>
      AttendanceRecord(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        date: date ?? this.date,
        status: status ?? this.status,
        sessions: sessions ?? this.sessions,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'date': date,
        'status': status,
        'sessions': sessions,
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as int?,
        clientId: map['clientId'] as int,
        date: map['date'] as String,
        status: map['status'] as String,
        sessions: (map['sessions'] as int?) ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          other.clientId == clientId &&
          other.date == date &&
          other.status == status &&
          other.sessions == sessions;

  @override
  int get hashCode => Object.hash(clientId, date, status, sessions);
}