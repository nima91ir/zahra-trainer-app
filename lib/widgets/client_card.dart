import 'package:flutter/material.dart';
import '../data/models/client.dart';
import '../data/models/client_plan.dart';
import '../theme/app_tokens.dart';
import '../utils/persian_numbers.dart';
import 'client_avatar.dart';
import 'status_badge.dart';

/// A single client row in the clients list.
class ClientCard extends StatelessWidget {
  final Client client;
  final ClientPlan? activePlan;
  final bool hasAttendedToday;
  final String? todayStatus; // 'present' | 'absent' | null
  final VoidCallback onTap;
  final VoidCallback? onMarkPresent;
  final VoidCallback? onMarkAbsent;
  final VoidCallback? onUndoAttendance;

  const ClientCard({
    super.key,
    required this.client,
    this.activePlan,
    required this.hasAttendedToday,
    this.todayStatus,
    required this.onTap,
    this.onMarkPresent,
    this.onMarkAbsent,
    this.onUndoAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final plan = activePlan;
    final remainingSessions = plan?.remaining ?? 0;
    final remainingDays = plan?.days ?? 0;

    final sessionsColor = remainingSessions > 5
        ? AppTokens.success
        : remainingSessions >= 2
            ? AppTokens.warning
            : AppTokens.error;
    final daysColor = remainingDays > 14
        ? AppTokens.success
        : remainingDays >= 7
            ? AppTokens.warning
            : AppTokens.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + name + chevron
              Row(
                children: [
                  ClientAvatar(name: client.name, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      client.name,
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_left,
                      color: AppTokens.onSurfaceVar, size: 18),
                ],
              ),
              const SizedBox(height: 10),

              // Plan badge row
              Row(
                children: [
                  if (plan != null)
                    StatusBadge(
                      text: plan.isFrozen ? 'یخ‌زده' : 'فعال',
                      variant: plan.isFrozen
                          ? BadgeVariant.amber
                          : BadgeVariant.primary,
                    )
                  else
                    const StatusBadge(
                        text: 'بدون برنامه',
                        variant: BadgeVariant.neutral),
                ],
              ),
              const SizedBox(height: 10),

              // Stats: remaining days | remaining sessions
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'روز باقی‌مانده',
                      value: fa(remainingDays),
                      color: daysColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppTokens.outlineVariant,
                  ),
                  Expanded(
                    child: _StatCell(
                      label: 'جلسات باقی‌مانده',
                      value: fa(remainingSessions),
                      color: sessionsColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Attendance row
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTokens.outlineVariant),
                  ),
                ),
                child: hasAttendedToday
                    ? Row(
                        children: [
                          const Text(
                            'حضور امروز:',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.onSurfaceVar,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onUndoAttendance,
                            child: StatusBadge(
                              text: todayStatus == 'present'
                                  ? 'حاضر ×'
                                  : 'غایب ×',
                              variant: todayStatus == 'present'
                                  ? BadgeVariant.green
                                  : BadgeVariant.red,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Text(
                            'حضور امروز:',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.onSurfaceVar,
                            ),
                          ),
                          const Spacer(),
                          _PillButton(
                            label: 'حاضر',
                            onTap: onMarkPresent,
                            bg: AppTokens.successSoft,
                            fg: AppTokens.success,
                          ),
                          const SizedBox(width: 6),
                          _PillButton(
                            label: 'غایب',
                            onTap: onMarkAbsent,
                            bg: AppTokens.errorSoft,
                            fg: AppTokens.error,
                          ),
                        ],
                      ),
              ),

              // Bonus badge
              if (client.bonusSessions > 0) ...[
                const SizedBox(height: 8),
                StatusBadge(
                  text: '+${fa(client.bonusSessions)} جلسه اضافه',
                  variant: BadgeVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell({
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  const _PillButton({
    required this.label,
    required this.onTap,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}