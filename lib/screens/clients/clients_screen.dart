import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jalali_calendar.dart' as jc;
import '../../widgets/client_card.dart';
import '../add_edit_client/add_edit_client_screen.dart';
import '../client_detail/client_detail_screen.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final todayStr = jc.JalaliDate.today().toString();

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.clients.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('کلاینت‌ها')),
        body: const Center(
          child: Text(
            'هنوز کلاینتی نداری',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('کلاینت‌ها')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.clients.length,
        itemBuilder: (context, index) {
          final c = state.clients[index];
          final plan = state.activePlanForClient(c.id!);
          final todayRec = state.attendance
              .where((a) => a.clientId == c.id && a.date == todayStr)
              .toList();
          final hasAttended = todayRec.isNotEmpty;
          final status = hasAttended ? todayRec.first.status : null;

          return ClientCard(
            client: c,
            activePlan: plan,
            hasAttendedToday: hasAttended,
            todayStatus: status,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientDetailScreen(clientId: c.id!),
                ),
              );
            },
            onMarkPresent: () => state.markAttendance(
                c.id!, 'present', todayStr),
            onMarkAbsent: () =>
                state.markAttendance(c.id!, 'absent', todayStr),
            onUndoAttendance: () =>
                state.undoAttendance(c.id!, todayStr),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditClientScreen(),
            ),
          );
        },
        heroTag: 'clients_fab',
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}