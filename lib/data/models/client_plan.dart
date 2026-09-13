/// A plan assigned to a specific client.
///
/// Status values:
///   \'active\'  — currently running
///   \'frozen\'  — paused; days do not count down
///   \'expired\' — finished or ran out of sessions
///   \'queued\'  — waiting for the current active plan to finish
///
/// When status == \'queued\', [startDate] is null and [queueOrder] is set
/// (1 = first in queue, 2 = second, etc.).
/// For all other statuses, [startDate] is set and [queueOrder] is null.
class ClientPlan {
  final int? id;
  final int clientId;
  final int templateId;
  final String? startDate;
  final int sessions;
  final int days;
  final int remaining;
  final String status;
  final int? queueOrder;

  const ClientPlan({
    this.id,
    required this.clientId,
    required this.templateId,
    this.startDate,
    required this.sessions,
    required this.days,
    required this.remaining,
    required this.status,
    this.queueOrder,
  });

  bool get isActive => status == 'active';
  bool get isFrozen => status == 'frozen';
  bool get isExpired => status == 'expired';
  bool get isQueued => status == 'queued';

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'templateId': templateId,
        'startDate': startDate,
        'sessions': sessions,
        'days': days,
        'remaining': remaining,
        'status': status,
        'queueOrder': queueOrder,
      };

  factory ClientPlan.fromMap(Map<String, dynamic> map) => ClientPlan(
        id: map['id'] as int?,
        clientId: map['clientId'] as int,
        templateId: map['templateId'] as int,
        startDate: map['startDate'] as String?,
        sessions: map['sessions'] as int,
        days: map['days'] as int,
        remaining: map['remaining'] as int,
        status: map['status'] as String,
        queueOrder: map['queueOrder'] as int?,
      );

  ClientPlan copyWith({
    int? id,
    int? clientId,
    int? templateId,
    String? startDate,
    bool clearStartDate = false,
    int? sessions,
    int? days,
    int? remaining,
    String? status,
    int? queueOrder,
    bool clearQueueOrder = false,
  }) =>
      ClientPlan(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        templateId: templateId ?? this.templateId,
        startDate: clearStartDate ? null : (startDate ?? this.startDate),
        sessions: sessions ?? this.sessions,
        days: days ?? this.days,
        remaining: remaining ?? this.remaining,
        status: status ?? this.status,
        queueOrder:
            clearQueueOrder ? null : (queueOrder ?? this.queueOrder),
      );
}