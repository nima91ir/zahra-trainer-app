import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/client.dart';
import '../../screens/client_detail/client_detail_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../utils/persian_numbers.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/jalali_calendar.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/stat_alert_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late jc.JalaliDate _viewMonth;

  @override
  void initState() {
    super.initState();
    final today = jc.JalaliDate.today();
    _viewMonth = jc.JalaliDate(today.year, today.month, 1);
  }

  Future<void> _openClientListSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tint,
    required List<Client> clients,
    String? actionLabel,
    Color? actionColor,
  }) async {
    await showAppSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.rMd),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: tint, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 11.5,
                        color: AppTokens.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTokens.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fa(clients.length),
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (clients.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'همه انجام شد',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.onSurfaceVar,
                  ),
                ),
              ),
            )
          else
            ...clients.where((c) => c.id != null).map((c) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ClientDetailScreen(clientId: c.id!),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTokens.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.rMd),
                      border:
                          Border.all(color: AppTokens.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        ClientAvatar(name: c.name, size: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTokens.onSurface,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                _metaFor(c),
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 11,
                                  color: AppTokens.onSurfaceVar,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (actionLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: actionColor ?? AppTokens.primary,
                              borderRadius: BorderRadius.circular(
                                  AppTokens.rMd),
                            ),
                            child: Text(
                              actionLabel,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  String _metaFor(Client c) {
    if (c.id == null) return '—';
    final state = context.read<AppState>();
    final plan = state.activePlanForClient(c.id!);
    if (c.bonusSessions > 0) {
      final bonus = '${fa(c.bonusSessions)} جلسه اضافه';
      if (plan != null) {
        return '$bonus · برنامه فعال: ${fa(plan.remaining)} جلسه';
      }
      return bonus;
    }
    if (plan != null) {
      return '${fa(plan.remaining)} جلسه · ${fa(plan.days)} روز';
    }
    return 'بدون برنامه';
  }

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
        state.clients.where((c) => c.id != null && c.bonusSessions > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('داشبورد'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
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
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTokens.primary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${today.weekdayName} ${fa(today.day)} ${today.monthName} ${fa(today.year)}',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.onSurfaceVar,
              ),
            ),
            SizedBox(height: 18),

            // Bonus banner
            if (bonusClients.isNotEmpty) ...[
_SectionLabel(text: 'جلسات اضافه'),
              SizedBox(height: 8),
              _BonusBanner(
                count: bonusClients.length,
onTap: () => _openClientListSheet(
                    title: 'جلسات اضافه',
                    subtitle: 'کلاینت‌هایی که جلسه اضافه دارند',
                    icon: Icons.add,
                    tint: AppTokens.primary,
                    clients: bonusClients,
                    actionLabel: 'مشاهده',
                  ),
              ),
              SizedBox(height: 18),
            ],

            // Calendar
            _SectionLabel(text: 'حضور این ماه'),
            SizedBox(height: 8),
            JalaliCalendar(
              year: _viewMonth.year,
              month: _viewMonth.month,
              presentCounts: presentCounts,
              absentCounts: absentCounts,
              onPrevMonth: () => setState(() {
                _viewMonth = _viewMonth.prevMonth();
              }),
              onNextMonth: () => setState(() {
                _viewMonth = _viewMonth.nextMonth();
              }),
            ),
            SizedBox(height: 18),

            // Alerts
            _SectionLabel(text: 'نیاز به توجه'),
            SizedBox(height: 8),
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
                  onTap: () => _openClientListSheet(
                    title: 'کلاینت‌های منقضی',
                    subtitle: 'برنامه‌شان تمام شده',
                    icon: Icons.calendar_today_outlined,
                    tint: AppTokens.error,
                    clients: state.clients.where((c) => c.id != null && state
                        .plansForClient(c.id!)
                        .any((p) => p.status == 'expired'))
                        .toList(),
                    actionLabel: 'تمدید',
                  ),
                ),
                StatAlertCard(
                  icon: Icons.ac_unit,
                  value: frozenCount,
                  label: 'یخ‌زده',
                  tint: AppTokens.primary,
                  onTap: () => _openClientListSheet(
                    title: 'یخ‌زده',
                    subtitle: 'می‌توانی بازشان کنی',
                    icon: Icons.ac_unit,
                    tint: AppTokens.primary,
                    clients: state.clients.where((c) => c.id != null && state
                        .plansForClient(c.id!)
                        .any((p) => p.status == 'frozen'))
                        .toList(),
                    actionLabel: 'باز کردن',
                    actionColor: AppTokens.success,
                  ),
                ),
                StatAlertCard(
                  icon: Icons.warning_amber_rounded,
                  value: lowCount,
                  label: 'در حال اتمام',
                  tint: AppTokens.warning,
                  onTap: () => _openClientListSheet(
                    title: 'در حال اتمام',
                    subtitle: '۳ جلسه یا کمتر',
                    icon: Icons.warning_amber_rounded,
                    tint: AppTokens.warning,
                    clients: state.clients.where((c) {
                      if (c.id == null) return false;
                      final p = state.activePlanForClient(c.id!);
                      return p != null && p.remaining <= 3;
                    }).toList(),
                    actionLabel: 'تمدید',
                  ),
                ),
                StatAlertCard(
                  icon: Icons.list_alt,
                  value: queuedCount,
                  label: 'در صف',
                  tint: AppTokens.primaryDark,
                  onTap: () => _openClientListSheet(
                    title: 'در صف',
                    subtitle: 'بعد از برنامه فعلی فعال می‌شوند',
                    icon: Icons.list_alt,
                    tint: AppTokens.primaryDark,
                    clients: state.clients.where((c) => c.id != null && state
                        .plansForClient(c.id!)
                        .any((p) => p.status == 'queued'))
                        .toList(),
                    actionLabel: 'مشاهده',
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),

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
        style: TextStyle(
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
  final VoidCallback onTap;
  const _BonusBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative radial highlight
        PositionedDirectional(
          top: -40,
          end: -40,
          width: 140,
          height: 140,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                 center: Alignment.topLeft,
                 radius: 1.2,
                 colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Main card
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [const Color(0xFF6B8452), const Color(0xFFB8A06B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(107, 132, 82, 0.45),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Chevron (start side in RTL)
                Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.7), size: 22),
                SizedBox(width: 14),
                // Body column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'کلاینت‌هایی که جلسه اضافه دارند',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        fa(count),
                        textAlign: TextAlign.start,
                        style: TextStyle(
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
                SizedBox(width: 14),
                // Icon box (end side in RTL)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.add,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ],
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
          Icon(Icons.chevron_right,
              color: AppTokens.onSurfaceVar, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'کل کلاینت‌ها',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.onSurfaceVar,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  fa(count),
                  textAlign: TextAlign.start,
                  style: TextStyle(
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
          Icon(Icons.chevron_left,
              color: AppTokens.onSurfaceVar, size: 20),
        ],
      ),
    );
  }
}
