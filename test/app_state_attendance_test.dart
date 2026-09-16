import 'package:flutter_test/flutter_test.dart';
import 'package:zahra_trainer/data/app_repository.dart';
import 'package:zahra_trainer/state/app_state.dart';
import 'package:zahra_trainer/data/models/client.dart';
import 'package:zahra_trainer/data/models/plan_template.dart';
import 'package:zahra_trainer/data/models/client_plan.dart';
import 'package:zahra_trainer/data/models/attendance_record.dart';

/// Fake repository for testing AppState without a real database.
class FakeAppRepository extends AppRepository {
  final List<Client> _clients = [];
  final List<PlanTemplate> _templates = [];
  final List<ClientPlan> _plans = [];
  final List<AttendanceRecord> _attendance = [];

  @override
  Future<List<Client>> getAllClients() async => List.from(_clients);

  @override
  Future<int> insertClient(Client client) async {
    final id = _clients.length + 1;
    _clients.add(client.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateClient(Client client) async {
    final idx = _clients.indexWhere((c) => c.id == client.id);
    if (idx != -1) _clients[idx] = client;
  }

  @override
  Future<void> deleteClient(int id) async {
    _clients.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> deleteClientCascade(int clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
    _plans.removeWhere((p) => p.clientId == clientId);
    _attendance.removeWhere((a) => a.clientId == clientId);
  }

  @override
  Future<List<PlanTemplate>> getAllTemplates() async => List.from(_templates);

  @override
  Future<int> insertTemplate(PlanTemplate template) async {
    final id = _templates.length + 1;
    _templates.add(template.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateTemplate(PlanTemplate template) async {
    final idx = _templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) _templates[idx] = template;
  }

  @override
  Future<void> deleteTemplate(int id) async {
    _templates.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<ClientPlan>> getAllPlans() async => List.from(_plans);

  @override
  Future<int> insertPlan(ClientPlan plan) async {
    final id = _plans.length + 1;
    _plans.add(plan.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updatePlan(ClientPlan plan) async {
    final idx = _plans.indexWhere((p) => p.id == plan.id);
    if (idx != -1) _plans[idx] = plan;
  }

  @override
  Future<void> deletePlan(int id) async {
    _plans.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<AttendanceRecord>> getAllAttendance() async => List.from(_attendance);

  @override
  Future<int> insertAttendance(AttendanceRecord record) async {
    final id = _attendance.length + 1;
    _attendance.add(record.copyWith(id: id));
    return id;
  }

  @override
  Future<void> deleteAttendance(int id) async {
    _attendance.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> deleteAllData() async {
    _clients.clear();
    _templates.clear();
    _plans.clear();
    _attendance.clear();
  }
}

AppState createTestAppState() {
  final repo = FakeAppRepository();
  return AppState(repo);
}

void main() {
  group('AppState attendance', () {
    test('markAttendance replaces existing record for same date', () async {
      final state = createTestAppState();

      state.clients.add(Client(id: 1, name: 'Test', tagIds: []));
      state.plans.add(ClientPlan(
        id: 1,
        clientId: 1,
        templateId: 1,
        startDate: '1404/01/01',
        sessions: 4,
        days: 30,
        remaining: 4,
        status: 'active',
      ));

      await state.markAttendance(1, 'present', '1404/06/21');

      expect(state.attendance.length, 1);
      expect(state.attendance.first.status, 'present');
      expect(state.attendance.first.date, '1404/06/21');

      await state.markAttendance(1, 'absent', '1404/06/21');

      expect(state.attendance.length, 1);
      expect(state.attendance.first.status, 'absent');
    });

    test('undoAttendance removes record and refunds session', () async {
      final state = createTestAppState();

      state.clients.add(Client(id: 1, name: 'Test', tagIds: []));
      state.plans.add(ClientPlan(
        id: 1,
        clientId: 1,
        templateId: 1,
        startDate: '1404/01/01',
        sessions: 4,
        days: 30,
        remaining: 3,
        status: 'active',
      ));

      await state.markAttendance(1, 'present', '1404/06/21');
      expect(state.attendance.length, 1);

      await state.undoAttendance(1, '1404/06/21');
      expect(state.attendance.length, 0);
      expect(state.activePlanForClient(1)?.remaining, greaterThan(2));
    });
  });
}
