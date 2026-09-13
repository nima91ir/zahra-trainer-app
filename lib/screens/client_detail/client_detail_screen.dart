import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/client.dart';
import '../../data/models/client_plan.dart';
import '../../state/app_state.dart';
import '../../screens/add_plan/add_plan_screen.dart';
import '../../screens/past_attendance/past_attendance_screen.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/status_badge.dart';
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
        appBar: AppBar(title: const Text('جزئیات')),
        body: const Center(
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
    final todayStatus =
        hasAttended ? todayRecords.first.status : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ویرایش — به‌زودی')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileCard(client: client, state: state),
          const SizedBox(height: 14),
          _AttendanceTodayCard(
            clientId: clientId,
            hasAttended: hasAttended,
            status: todayStatus,
            onMark: (s) =>
                state.markAttendance(clientId, s, todayStr),
            onUndo: () =>
                state.undoAttendance(clientId, todayStr),
          ),
          if (activePlan != null) ...[
            const SizedBox(height: 14),
            _ActivePlanCard(plan: activePlan),
          ],
          const SizedBox(height: 14),
          _AddPlanButton(clientId: clientId),
          const SizedBox(height: 14),
          _BonusSection(client: client),
          const SizedBox(height: 20),
          _AttendanceHistorySection(clientId: clientId),
          const SizedBox(height: 20),
          _PastPlansSection(clientId: clientId),
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          Text(
            client.name,
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTokens.onSurface,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: tags
                  .map((t) => StatusBadge(
                        text: '${t.emoji} ${t.name}',
                        variant: BadgeVariant.primary,
                      ))
                  .toList(),
            ),
          ],
          if (client.contact != null &&
              client.contact!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                client.contact!,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
            ),
          ],
          if (client.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.background,
                borderRadius: BorderRadius.circular(AppTokens.rSm),
              ),
              child: Text(
                client.note,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
          const Text(
            'حضور امروز',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTokens.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (hasAttended)
            Row(
              children: [
                StatusBadge(
                  text: status == 'present' ? 'حاضر' : 'غایب',
                  variant: status == 'present'
                      ? BadgeVariant.green
                      : BadgeVariant.red,
                ),
                const Spacer(),
                TextButton(
                  onPressed: onUndo,
                  child: const Text(
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
                const SizedBox(width: 8),
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
  const _BigPill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

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
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.onSurface,
                  ),
                ),
              ),
              StatusBadge(
                text: plan.isFrozen ? 'یخ‌زده' : 'فعال',
                variant: plan.isFrozen
                    ? BadgeVariant.amber
                    : BadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
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
                  Container(
                    width: 1,
                    height: 34,
                    color: AppTokens.outlineVariant,
                  ),
                  Expanded(
                    child: _PlanStat(
                      label: 'مدت اعتبار',
                      value: '${fa(plan.days)} روز',
                      color: AppTokens.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PastAttendanceScreen(
                      clientId: plan.clientId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 18),
              label: const Text('حضور گذشته'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.primary,
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: AppTokens.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
  const _PlanStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Vazir',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTokens.onSurfaceVar,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
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
          MaterialPageRoute(
            builder: (_) => AddPlanScreen(clientId: clientId),
          ),
        );
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('افزودن برنامه جدید'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppTokens.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جلسات اضافه',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'حتی بعد از اتمام برنامه قابل استفاده است',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fa(client.bonusSessions),
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.adjustBonus(client.id!, 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.primary,
                    minimumSize: const Size.fromHeight(40),
                    side: const BorderSide(color: AppTokens.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.rMd),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('+ افزودن'),
                ),
              ),
              if (client.bonusSessions > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        state.adjustBonus(client.id!, -1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.primary,
                      minimumSize: const Size.fromHeight(40),
                      side: const BorderSide(
                          color: AppTokens.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.rMd),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('- کم کردن'),
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

class _AttendanceHistorySection extends StatelessWidget {
  final int clientId;
  const _AttendanceHistorySection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state
        .attendanceForClient(clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'تاریخچه حضور',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTokens.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'هنوز حضوری ثبت نشده',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12.5,
                  color: AppTokens.onSurfaceVar,
                ),
              ),
            ),
          )
        else
          ...records.take(8).map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                  border: Border.all(color: AppTokens.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppTokens.onSurfaceVar),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.date,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.onSurface,
                        ),
                      ),
                    ),
                    StatusBadge(
                      text: r.isPresent ? 'حاضر' : 'غایب',
                      variant: r.isPresent
                          ? BadgeVariant.green
                          : BadgeVariant.red,
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

class _PastPlansSection extends StatelessWidget {
  final int clientId;
  const _PastPlansSection({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pastPlans = state
        .plansForClient(clientId)
        .where((p) => p.status == 'expired')
        .toList();

    if (pastPlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'برنامه‌های گذشته',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTokens.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...pastPlans.map((p) {
          final template = state.templateById(p.templateId);
          return Container(
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
                  decoration: BoxDecoration(
                    color: AppTokens.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fitness_center,
                      size: 16, color: AppTokens.onSurfaceVar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template?.name ?? 'برنامه',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'شروع: ${p.startDate ?? '—'}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 11,
                          color: AppTokens.onSurfaceVar,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                    text: 'منقضی', variant: BadgeVariant.red),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DeleteClientButton extends StatelessWidget {
  final Client client;
  const _DeleteClientButton({required this.client});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('حذف کلاینت'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.error,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(
            color: AppTokens.error.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف کلاینت',
          style: TextStyle(
              fontFamily: 'Vazir', fontWeight: FontWeight.w800),
        ),
        content: Text(
          'آیا از حذف «${client.name}» اطمینان داری؟ تمام برنامه‌ها و سوابق حضور نیز حذف می‌شوند.',
          style: const TextStyle(fontFamily: 'Vazir', height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لغو',
                style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (client.id != null) {
                state.deleteClient(client.id!);
                nav.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('کلاینت حذف شد')),
                );
              }
            },
            child: const Text('حذف',
                style: TextStyle(
                    fontFamily: 'Vazir',
                    color: AppTokens.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}