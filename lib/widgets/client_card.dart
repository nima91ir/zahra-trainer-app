import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/client.dart';
import '../data/models/client_plan.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../utils/persian_numbers.dart';
import 'client_avatar.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final ClientPlan? activePlan;
  final bool hasAttendedToday;
  final String? todayStatus;
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
    final state = context.watch<AppState>();
    final tags = state.tagsForClient(client);
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Header: avatar + name + chevron
              Row(
                children: [
                  ClientAvatar(name: client.name, size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      client.name,
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_left,
                      color: AppTokens.onSurfaceVar, size: 18),
                ],
              ),
              SizedBox(height: 10),

            // Tags row
            if (tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTokens.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.name, // Remove emoji from tag pill
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
              SizedBox(height: 10),
            ],

              // Note
              if (client.note.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: Text(
                    client.note,
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 11.5,
                      color: AppTokens.onSurfaceVar,
                      height: 1.7,
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],

              // Stats: remaining days | remaining sessions
              if (plan != null) ...[
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
                SizedBox(height: 10),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: Text(
                    'بدون برنامه فعال',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.onSurfaceVar,
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],

              // Attendance row
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTokens.outlineVariant),
                  ),
                ),
                child: hasAttendedToday
                    ? Row(
                        children: [
                          Text(
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 4),
                              decoration: BoxDecoration(
                                color: todayStatus == 'present'
                                    ? AppTokens.successSoft
                                    : AppTokens.errorSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                todayStatus == 'present' ? 'حاضر ×' : 'غایب ×',
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: todayStatus == 'present'
                                      ? AppTokens.success
                                      : AppTokens.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
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
                          SizedBox(width: 6),
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
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTokens.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${fa(client.bonusSessions)} جلسه اضافه',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.primary,
                    ),
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTokens.onSurfaceVar,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.end,
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
