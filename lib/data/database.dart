import 'package:sembast/sembast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'db_factory_native.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';

import 'models/client.dart';
import 'models/tag.dart';
import 'models/plan_template.dart';
import 'models/client_plan.dart';
import 'models/attendance_record.dart';

/// Sembast database wrapper.
/// Singleton — use AppDatabase.instance everywhere.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'zahra_trainer.db';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      return await dbFactory.openDatabase(_dbName);
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return await dbFactory.openDatabase(path);
  }

  // –– Stores ––
  static const String storeClients = 'clients';
  static const String storeTags = 'tags';
  static const String storeTemplates = 'templates';
  static const String storePlans = 'plans';
  static const String storeAttendance = 'attendance';

  /// Exposes the internal database instance.
  Future<Database> get database async => _database;

  // –– Clients ––
  Future<List<Client>> getAllClients() async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeClients);
    final records = await store.find(db);
    return records.map((r) => Client.fromMap(r.value)).toList();
  }

  Future<int> insertClient(Client client) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeClients);
    final map = Map<String, dynamic>.from(client.toMap())..remove('id');
    return await store.add(db, map);
  }

  Future<void> updateClient(Client client) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeClients);
    await store.record(client.id!).update(db, client.toMap());
  }

  Future<void> deleteClient(int id) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeClients);
    await store.record(id).delete(db);
  }

  // –– Tags ––
  Future<List<Tag>> getAllTags() async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTags);
    final records = await store.find(db);
    return records.map((r) => Tag.fromMap(r.value)).toList();
  }

  Future<int> insertTag(Tag tag) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTags);
    final map = Map<String, dynamic>.from(tag.toMap())..remove('id');
    return await store.add(db, map);
  }

  Future<void> deleteTag(int id) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTags);
    await store.record(id).delete(db);
  }

  // –– Templates ––
  Future<List<PlanTemplate>> getAllTemplates() async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTemplates);
    final records = await store.find(db);
    return records.map((r) => PlanTemplate.fromMap(r.value)).toList();
  }

  Future<int> insertTemplate(PlanTemplate template) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTemplates);
    final map = Map<String, dynamic>.from(template.toMap())..remove('id');
    return await store.add(db, map);
  }

  Future<void> updateTemplate(PlanTemplate template) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTemplates);
    await store.record(template.id!).update(db, template.toMap());
  }

  Future<void> deleteTemplate(int id) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeTemplates);
    await store.record(id).delete(db);
  }

  // –– Plans ––
  Future<List<ClientPlan>> getAllPlans() async {
    final db = await _database;
    final store = intMapStoreFactory.store(storePlans);
    final records = await store.find(db);
    return records.map((r) => ClientPlan.fromMap(r.value)).toList();
  }

  Future<List<ClientPlan>> getPlansByClient(int clientId) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storePlans);
    final records = await store.find(
      db,
      finder: Finder(filter: Filter.equals('clientId', clientId)),
    );
    return records.map((r) => ClientPlan.fromMap(r.value)).toList();
  }

  Future<int> insertPlan(ClientPlan plan) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storePlans);
    final map = Map<String, dynamic>.from(plan.toMap())..remove('id');
    return await store.add(db, map);
  }

  Future<void> updatePlan(ClientPlan plan) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storePlans);
    await store.record(plan.id!).update(db, plan.toMap());
  }

  Future<void> deletePlan(int id) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storePlans);
    await store.record(id).delete(db);
  }

  // –– Attendance ––
  Future<List<AttendanceRecord>> getAllAttendance() async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeAttendance);
    final records = await store.find(db);
    return records.map((r) => AttendanceRecord.fromMap(r.value)).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByClient(int clientId) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeAttendance);
    final records = await store.find(
      db,
      finder: Finder(filter: Filter.equals('clientId', clientId)),
    );
    return records.map((r) => AttendanceRecord.fromMap(r.value)).toList();
  }

  Future<int> insertAttendance(AttendanceRecord record) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeAttendance);
    final map = Map<String, dynamic>.from(record.toMap())..remove('id');
    return await store.add(db, map);
  }

  Future<void> deleteAttendance(int id) async {
    final db = await _database;
    final store = intMapStoreFactory.store(storeAttendance);
    await store.record(id).delete(db);
  }

  // –– Cascade delete ––
  /// Deletes a client AND all their plans AND all their attendance.
  Future<void> deleteClientCascade(int clientId) async {
    final db = await _database;

    // 1. Attendance
    final attStore = intMapStoreFactory.store(storeAttendance);
    final attRecords = await attStore.find(
      db,
      finder: Finder(filter: Filter.equals('clientId', clientId)),
    );
    for (final r in attRecords) {
      await attStore.record(r.key).delete(db);
    }

    // 2. Plans
    final planStore = intMapStoreFactory.store(storePlans);
    final planRecords = await planStore.find(
      db,
      finder: Finder(filter: Filter.equals('clientId', clientId)),
    );
    for (final r in planRecords) {
      await planStore.record(r.key).delete(db);
    }

    // 3. Client
    await deleteClient(clientId);
  }
}