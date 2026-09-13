import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/jalali_calendar.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/stat_alert_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = jc.JalaliDate.today();

    // Attendance dots for the current month
    final presentCounts = <String, int>{};
    final absentCounts = <String, int>{};
    for (final rec in state.attendance) {
      if (rec.status == 'present') {
        presentCounts[rec.date] = (presentCounts[rec.date] ?? 0) + 1;
      } else if (rec.status == 'absent') {
        absentCounts[rec.date] = (absentCounts[rec.date] ?? 0) + 1;
      }
    }

    // Alert counts
    final expiredCount =
        state.plans.where((p) => p.status == 'expired').length;
    final frozenCount =
        state.plans.where((p) => p.status == 'frozen').length;
    final lowCount = state.plans
        .where((p) => p.status == 'active' && p.remaining <= 3)
        .length;
    final queuedCount =
        state.plans.where((p) => p.status == 'queued').length;

    // Bonus banner
    final bonusClients =
        state.clients.where((c) => c.bonusSessions > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Welcome
            Text(
              state.userName.isEmpty
                  ? 'سلام 👋'
                  : 'سلام ${state.userName} 👋',
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTokens.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'امروز: ${today.monthName} ${fa(today.day)}',
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.onSurfaceVar,
              ),
            ),
            const SizedBox(height: 18),

            // Bonus banner
            if (bonusClients.isNotEmpty) ...[
              _SectionLabel(text: 'جلسات اضافه'),
              const SizedBox(height: 8),
              _BonusBanner(count: bonusClients.length),
              const SizedBox(height: 18),
            ],

            // Calendar
            _SectionLabel(text: 'حضور این ماه'),
            const SizedBox(height: 8),
            JalaliCalendar(
              year: today.year,
              month: today.month,
              presentCounts: presentCounts,
              absentCounts: absentCounts,
              onPrevMonth: () {},
              onNextMonth: () {},
            ),
            const SizedBox(height: 18),

            // Alerts
            _SectionLabel(text: 'نیاز به توجه'),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                StatAlertCard(
                  icon: Icons.calendar_today_outlined,
                  value: expiredCount,
                  label: 'منقضی',
                  tint: AppTokens.error,
                  onTap: () {},
                ),
                StatAlertCard(
                  icon: Icons.ac_unit,
                  value: frozenCount,
                  label: 'یخ‌زده',
                  tint: AppTokens.primary,
                  onTap: () {},
                ),
                StatAlertCard(
                  icon: Icons.warning_amber_rounded,
                  value: lowCount,
                  label: 'در حال اتمام',
                  tint: AppTokens.warning,
                  onTap: () {},
                ),
                StatAlertCard(
                  icon: Icons.list_alt,
                  value: queuedCount,
                  label: 'در صف',
                  tint: AppTokens.primaryDark,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Total clients
            _TotalClientsCard(count: state.clients.length),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppTokens.onSurface,
        ),
      ),
    );
  }
}

class _BonusBanner extends StatelessWidget {
  final int count;
  const _BonusBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTokens.primaryDark, AppTokens.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'کلاینت‌هایی که جلسه اضافه دارند',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fa(count),
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
        ],
      ),
    );
  }
}

class _TotalClientsCard extends StatelessWidget {
  final int count;
  const _TotalClientsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTokens.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.people_outline,
                color: AppTokens.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'کل کلاینت‌ها',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.onSurfaceVar,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fa(count),
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left,
              color: AppTokens.onSurfaceVar, size: 20),
        ],
      ),
    );
  }
}