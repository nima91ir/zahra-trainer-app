import 'package:sembast/sembast.dart';

import 'database.dart';
import 'models/client.dart';
import 'models/tag.dart';
import 'models/plan_template.dart';
import 'models/client_plan.dart';
import 'models/attendance_record.dart';

/// Repository wrapping all Sembast CRUD operations.
/// AppState depends on this instead of AppDatabase directly.
class AppRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<Database> get _database async => _db.database;

  // –– Clients ––

  Future<List<Client>> getAllClients() async {
    return await _db.getAllClients();
  }

  Future<int> insertClient(Client client) async {
    return await _db.insertClient(client);
  }

  Future<void> updateClient(Client client) async {
    await _db.updateClient(client);
  }

  Future<void> deleteClient(int id) async {
    await _db.deleteClient(id);
  }

  Future<void> deleteClientCascade(int clientId) async {
    await _db.deleteClientCascade(clientId);
  }

  // –– Tags ––

  Future<List<Tag>> getAllTags() async {
    return await _db.getAllTags();
  }

  Future<int> insertTag(Tag tag) async {
    return await _db.insertTag(tag);
  }

  Future<void> deleteTag(int id) async {
    await _db.deleteTag(id);
  }

  // –– Templates ––

  Future<List<PlanTemplate>> getAllTemplates() async {
    return await _db.getAllTemplates();
  }

  Future<int> insertTemplate(PlanTemplate template) async {
    return await _db.insertTemplate(template);
  }

  Future<void> updateTemplate(PlanTemplate template) async {
    await _db.updateTemplate(template);
  }

  Future<void> deleteTemplate(int id) async {
    await _db.deleteTemplate(id);
  }

  // –– Plans ––

  Future<List<ClientPlan>> getAllPlans() async {
    return await _db.getAllPlans();
  }

  Future<int> insertPlan(ClientPlan plan) async {
    return await _db.insertPlan(plan);
  }

  Future<void> updatePlan(ClientPlan plan) async {
    await _db.updatePlan(plan);
  }

  Future<void> deletePlan(int id) async {
    await _db.deletePlan(id);
  }

  // –– Attendance ––

  Future<List<AttendanceRecord>> getAllAttendance() async {
    return await _db.getAllAttendance();
  }

  Future<int> insertAttendance(AttendanceRecord record) async {
    return await _db.insertAttendance(record);
  }

  Future<void> deleteAttendance(int id) async {
    await _db.deleteAttendance(id);
  }

  // –– Bulk operations ––

  Future<void> deleteAllData() async {
    final db = await _database;
    for (final store in [
      'clients',
      'tags',
      'templates',
      'plans',
      'attendance',
    ]) {
      final s = intMapStoreFactory.store(store);
      await s.delete(db);
    }
  }

  Future<Database> get database async => _database;
}
