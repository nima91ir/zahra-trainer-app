/// A single attendance mark for a client on a given Jalali date.
class AttendanceRecord {
  final int? id;
  final int clientId;
  final String date;   // Jalali string like '۱۴۰۵/۰۶/۲۱'
  final String status; // 'present' | 'absent'

  const AttendanceRecord({
    this.id,
    required this.clientId,
    required this.date,
    required this.status,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'date': date,
        'status': status,
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as int?,
        clientId: map['clientId'] as int,
        date: map['date'] as String,
        status: map['status'] as String,
      );

  AttendanceRecord copyWith({
    int? id,
    int? clientId,
    String? date,
    String? status,
  }) =>
      AttendanceRecord(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        date: date ?? this.date,
        status: status ?? this.status,
      );
}