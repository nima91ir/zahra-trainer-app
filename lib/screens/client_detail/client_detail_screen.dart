import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart' as shamsi;

import '../../data/models/client.dart';
import '../../data/models/client_plan.dart';
import '../../data/models/attendance_record.dart';
import '../../state/app_state.dart';
import '../../screens/add_edit_client/add_edit_client_screen.dart';
import '../../screens/add_plan/add_plan_screen.dart';
import '../../screens/past_attendance/past_attendance_screen.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/client_avatar.dart';
import '../../theme/app_tokens.dart';

class ClientDetailScreen extends StatelessWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final client = state.clientById(clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: Text('جزئیات')),
        body: Center(
          child: Text(
            'کلاینت پیدا نشد',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
        ),
      );
    }

    final todayStr = jc.JalaliDate.today().toString();
    final activePlan = state.activePlanForClient(clientId);
    final todayRecords = state.attendance
        .where((a) => a.clientId == clientId && a.date == todayStr)
        .toList();
    final hasAttended = todayRecords.isNotEmpty;
    final todayStatus = hasAttended ? todayRecords.first.status : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditClientScreen(existing: client),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileCard(client: client, state: state),
          SizedBox(height: 14),
          _AttendanceTodayCard(
            clientId: clientId,
            hasAttended: hasAttended,
            status: todayStatus,
            onMark: (s) => state.markAttendance(clientId, s, todayStr),
            onUndo: () => state.undoAttendance(clientId, todayStr),
          ),
          if (activePlan != null) ...[
            SizedBox(height: 14),
            _ActivePlanCard(plan: activePlan),
          ],
          SizedBox(height: 14),
          _QueuedPlansSection(clientId: clientId),
          SizedBox(height: 14),
          _AddPlanButton(clientId: clientId),
          SizedBox(height: 14),
          _BonusSection(client: client),
          SizedBox(height: 20),
          _AttendanceHistorySection(clientId: clientId),
          SizedBox(height: 20),
          _PastPlansSection(clientId: clientId),
          SizedBox(height: 20),
          _DeleteClientButton(client: client),
        ],
      ),
    );
  }
}

// ═══════════════ Profile ═══════════════
class _ProfileCard extends StatelessWidget {
  final Client client;
  final AppState state;
  const _ProfileCard({required this.client, required this.state});

  @override
  Widget build(BuildContext context) {
    final tags = state.tagsForClient(client);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Column(
        children: [
          ClientAvatar(name: client.name, size: 80),
          SizedBox(height: 12),
          Text(
            client.name,
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTokens.onSurface,
            ),
          ),
            if (tags.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTokens.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.name, // Remove emoji from tags in profile
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.primary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          if (client.contact != null && client.contact!.isNotEmpty) ...[
            SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                client.contact!,
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
            ),
          ],
          if (client.note.isNotEmpty) ...[
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.background,
                borderRadius: BorderRadius.circular(AppTokens.rSm),
              ),
              child: Text(
                client.note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.onSurfaceVar,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════ Attendance Today ═══════════════
class _AttendanceTodayCard extends StatelessWidget {
  final int clientId;
  final bool hasAttended;
  final String? status;
  final ValueChanged<String> onMark;
  final VoidCallback onUndo;

  const _AttendanceTodayCard({
    required this.clientId,
    required this.hasAttended,
    required this.status,
    required this.onMark,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حضور امروز',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTokens.onSurface,
            ),
          ),
          SizedBox(height: 10),
          if (hasAttended)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'present' ? AppTokens.successSoft : AppTokens.errorSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status == 'present' ? 'حاضر' : 'غایب',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status == 'present' ? AppTokens.success : AppTokens.error,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onUndo,
                  child: Text(
                    'واگرد',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      color: AppTokens.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _BigPill(
                    label: 'حاضر',
                    bg: AppTokens.successSoft,
                    fg: AppTokens.success,
                    onTap: () => onMark('present'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _BigPill(
                    label: 'غایب',
                    bg: AppTokens.errorSoft,
                    fg: AppTokens.error,
                    onTap: () => onMark('absent'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BigPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _BigPill({required this.label, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTokens.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════ Active Plan ═══════════════
class _ActivePlanCard extends StatelessWidget {
  final ClientPlan plan;
  const _ActivePlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final template = state.templateById(plan.templateId);
    final sessionsColor = plan.remaining > 5
        ? AppTokens.success
        : plan.remaining >= 2
            ? AppTokens.warning
            : AppTokens.error;
    final daysColor = plan.days > 14
        ? AppTokens.success
        : plan.days >= 7
            ? AppTokens.warning
            : AppTokens.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template?.name ?? 'برنامه',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: plan.isFrozen ? AppTokens.warningSoft : AppTokens.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.isFrozen ? 'یخ‌زده' : 'فعال',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: plan.isFrozen ? AppTokens.warning : AppTokens.primary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18),
                color: AppTokens.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDeletePlan(context, plan),
              ),
            ],
          ),
          SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTokens.background,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PlanStat(
                    label: 'جلسات باقی‌مانده',
                    value: fa(plan.remaining),
                    color: sessionsColor,
                  ),
                ),
                Container(width: 1, height: 34, color: AppTokens.outlineVariant),
                Expanded(
                  child: _PlanStat(
                    label: 'روز باقی‌مانده',
                    value: '${fa(plan.days)} روز',
                    color: daysColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (plan.isFrozen) {
                      state.unfreezePlan(plan.id!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برنامه باز شد')));
                    } else {
                      state.freezePlan(plan.id!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برنامه یخ‌زده شد')));
                    }
                  },
                  icon: Icon(plan.isFrozen ? Icons.lock_open : Icons.ac_unit, size: 18),
                  label: Text(plan.isFrozen ? 'باز کردن' : 'یخ زدن'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.primary,
                    minimumSize: const Size.fromHeight(40),
                    side: BorderSide(color: AppTokens.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
                    textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context, ClientPlan plan) {
    final state = context.read<AppState>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف برنامه', style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w800)),
        content: Text('آیا از حذف این برنامه اطمینان داری؟', style: TextStyle(fontFamily: 'Vazir', height: 1.8)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('لغو', style: TextStyle(fontFamily: 'Vazir'))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (plan.id != null) {
                state.deletePlan(plan.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برنامه حذف شد')));
              }
            },
            child: Text('حذف', style: TextStyle(fontFamily: 'Vazir', color: AppTokens.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PlanStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Vazir', fontSize: 11, fontWeight: FontWeight.w500, color: AppTokens.onSurfaceVar),
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontFamily: 'Vazir', fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1),
        ),
      ],
    );
  }
}

// ═══════════════ Queued Plans ═══════════════
class _QueuedPlansSection extends StatelessWidget {
  final int clientId;
  const _QueuedPlansSection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final queuedPlans = state.queuedPlansForClient(clientId);
    if (queuedPlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'در صف',
            style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.onSurface),
          ),
        ),
        SizedBox(height: 10),
        ...queuedPlans.map((p) {
          final template = state.templateById(p.templateId);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
              border: Border.all(color: AppTokens.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template?.name ?? 'برنامه',
                        style: TextStyle(fontFamily: 'Vazir', fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTokens.onSurface),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'صف ${fa(p.queueOrder ?? 1)}',
                        style: TextStyle(fontFamily: 'Vazir', fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18),
                      color: AppTokens.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (p.id != null) state.deletePlan(p.id!);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'بعد از تمام شدن برنامه فعلی، خودکار فعال می‌شود.',
                  style: TextStyle(fontFamily: 'Vazir', fontSize: 12, color: AppTokens.onSurfaceVar, height: 1.7),
                ),
                SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppTokens.background, borderRadius: BorderRadius.circular(AppTokens.rMd)),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PlanStat(label: 'جلسات', value: fa(p.sessions), color: AppTokens.onSurface),
                      ),
                      Container(width: 1, height: 34, color: AppTokens.outlineVariant),
                      Expanded(
                        child: _PlanStat(label: 'مدت', value: '${fa(p.days)} روز', color: AppTokens.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════ Add Plan Button ═══════════════
class _AddPlanButton extends StatelessWidget {
  final int clientId;
  const _AddPlanButton({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPlanScreen(clientId: clientId)),
        );
      },
      icon: Icon(Icons.add, size: 18),
      label: Text('افزودن برنامه جدید'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.primary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: AppTokens.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rLg)),
        textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ═══════════════ Bonus Section ═══════════════
class _BonusSection extends StatelessWidget {
  final Client client;
  const _BonusSection({required this.client});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جلسات اضافه', style: TextStyle(fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
                    SizedBox(height: 2),
                    Text('حتی بعد از اتمام برنامه قابل استفاده است', style: TextStyle(fontFamily: 'Vazir', fontSize: 11.5, fontWeight: FontWeight.w500, color: AppTokens.onSurfaceVar)),
                  ],
                ),
              ),
              Text(
                fa(client.bonusSessions),
                style: TextStyle(fontFamily: 'Vazir', fontSize: 22, fontWeight: FontWeight.w900, color: AppTokens.primary),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.adjustBonus(client.id!, 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.primary,
                    minimumSize: const Size.fromHeight(40),
                    side: BorderSide(color: AppTokens.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
                    textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: Text('+ افزودن'),
                ),
              ),
              if (client.bonusSessions > 0) ...[
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => state.adjustBonus(client.id!, -1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.primary,
                      minimumSize: const Size.fromHeight(40),
                      side: BorderSide(color: AppTokens.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
                      textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: Text('- کم کردن'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════ Attendance History ═══════════════
class _AttendanceHistorySection extends StatelessWidget {
  final int clientId;
  const _AttendanceHistorySection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.attendanceForClient(clientId).toList()..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('تاریخچه حضور', style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
        ),
        SizedBox(height: 10),
        if (records.isEmpty)
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PastAttendanceScreen(clientId: clientId),
                    ),
                  );
                },
                icon: Icon(Icons.history, size: 18),
                label: Text('افزودن حضور گذشته', style: TextStyle(fontFamily: 'Vazir')),
              ),
            ),
          )
        else
          ...records.take(8).map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                  border: Border.all(color: AppTokens.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTokens.onSurfaceVar),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(r.date, style: TextStyle(fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.status == 'present' ? AppTokens.successSoft : AppTokens.errorSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        r.status == 'present' ? 'حاضر' : 'غایب',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: r.status == 'present' ? AppTokens.success : AppTokens.error,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, size: 18, color: AppTokens.error),
                      onPressed: () => context.read<AppState>().undoAttendance(clientId, r.date),
                      tooltip: 'کاهش جلسه',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${r.sessions}',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, size: 18, color: AppTokens.primary),
                      onPressed: () => context.read<AppState>().addAttendanceSession(clientId, r.date),
                      tooltip: 'افزایش جلسه',
                    ),
                  ],
                ),
              )),
          SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PastAttendanceScreen(clientId: clientId),
                ),
              );
            },
            icon: Icon(Icons.history, size: 18),
            label: Text('افزودن حضور گذشته', style: TextStyle(fontFamily: 'Vazir')),
          ),
      ],
    );
  }
}

// ═══════════════ Past Plans ═══════════════
class _PastPlansSection extends StatelessWidget {
  final int clientId;
  const _PastPlansSection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pastPlans = state.plansForClient(clientId).where((p) => p.status == 'expired').toList();

    if (pastPlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('برنامه‌های گذشته', style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
        ),
        SizedBox(height: 10),
        ...pastPlans.map((p) {
          final template = state.templateById(p.templateId);
          return InkWell(
            onTap: () {
              final state = context.read<AppState>();
              final template = state.templateById(p.templateId);
              final duration = template?.days ?? p.days;

              final start = jc.JalaliDate.tryParse(p.startDate ?? '');
              if (start == null) return;

              final startJdn = start.toJdn();
              final endJdn = startJdn + duration - 1;
              final endDateTime = shamsi.Jalali(start.year, start.month, start.day).toDateTime().add(Duration(days: duration - 1));
              final endJalali = shamsi.Jalali.fromDateTime(endDateTime);
              final endDateStr = jc.JalaliDate(endJalali.year, endJalali.month, endJalali.day).toString();

              final rawRecords = state.attendance
                  .where((a) => a.clientId == clientId)
                  .where((a) {
                    final date = jc.JalaliDate.tryParse(a.date);
                    if (date == null) return false;
                    final jdn = date.toJdn();
                    return jdn >= startJdn && jdn <= endJdn;
                  })
                  .toList();

              final bestByDate = <String, AttendanceRecord>{};
              for (final r in rawRecords) {
                final existing = bestByDate[r.date];
                if (existing == null) {
                  bestByDate[r.date] = r;
                } else {
                  final existingScore = existing.status == 'present' ? 1 : 0;
                  final newScore = r.status == 'present' ? 1 : 0;
                  if (newScore > existingScore ||
                      (newScore == existingScore &&
                          (r.id ?? 0) > (existing.id ?? 0))) {
                    bestByDate[r.date] = r;
                  }
                }
              }

              final records = bestByDate.values.toList()
                ..sort((a, b) {
                  final da = jc.JalaliDate.tryParse(a.date);
                  final db = jc.JalaliDate.tryParse(b.date);
                  if (da == null || db == null) return 0;
                  return da.toJdn().compareTo(db.toJdn());
                });

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('${template?.name ?? 'برنامه'} ($start — $endDateStr)', style: TextStyle(fontFamily: 'Vazir')),
                  content: records.isEmpty
                      ? Text('هیچ رکورد حضوری یافت نشد', style: TextStyle(fontFamily: 'Vazir'))
                      : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: records.length,
                            itemBuilder: (ctx, i) {
                              final r = records[i];
                              return ListTile(
                                dense: true,
                                title: Text(r.date, style: TextStyle(fontFamily: 'Vazir')),
                                trailing: Text(
                                  r.status == 'present' ? 'حاضر' : 'غایب',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    color: r.status == 'present' ? AppTokens.success : AppTokens.error,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('بستن', style: TextStyle(fontFamily: 'Vazir')),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                border: Border.all(color: AppTokens.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppTokens.background, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Icon(Icons.fitness_center, size: 16, color: AppTokens.onSurfaceVar),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template?.name ?? 'برنامه', style: TextStyle(fontFamily: 'Vazir', fontSize: 13, fontWeight: FontWeight.w800, color: AppTokens.onSurface)),
                        SizedBox(height: 2),
                        Text('شروع: ${p.startDate ?? '—'} · ${fa(p.days)} روز', style: TextStyle(fontFamily: 'Vazir', fontSize: 11, color: AppTokens.onSurfaceVar)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppTokens.errorSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text('منقضی', style: TextStyle(fontFamily: 'Vazir', fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.error)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════ Delete Client Button ═══════════════
class _DeleteClientButton extends StatelessWidget {
  final Client client;
  const _DeleteClientButton({required this.client});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: Icon(Icons.delete_outline, size: 18),
      label: Text('حذف کلاینت'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.error,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: AppTokens.error.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rLg)),
        textStyle: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف کلاینت', style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w800)),
        content: Text(
          'آیا از حذف «${client.name}» اطمینان داری؟ تمام برنامه‌ها و سوابق حضور نیز حذف می‌شوند.',
          style: TextStyle(fontFamily: 'Vazir', height: 1.8),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('لغو', style: TextStyle(fontFamily: 'Vazir'))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (client.id != null) {
                state.deleteClient(client.id!);
                nav.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کلاینت حذف شد')));
              }
            },
            child: Text('حذف', style: TextStyle(fontFamily: 'Vazir', color: AppTokens.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
