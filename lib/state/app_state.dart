import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_repository.dart';
import '../data/models/client.dart';
import '../data/models/tag.dart';
import '../data/models/plan_template.dart';
import '../data/models/client_plan.dart';
import '../data/models/attendance_record.dart';
import '../utils/jalali_calendar.dart' as jc;

/// Central app state.
/// Every mutation calls notifyListeners() at the end.
class AppState extends ChangeNotifier {
  final AppRepository _repository;

  AppState(this._repository);

  // ─── Raw data ───
  List<Client> clients = [];
  List<PlanTemplate> templates = [];
  List<ClientPlan> plans = [];
  List<AttendanceRecord> attendance = [];
  List<Tag> tags = [];

  // ─── Indexes for O(1) lookups ───
  final Map<int, Client> _clientMap = {};
  final Map<int, PlanTemplate> _templateMap = {};
  final Map<int, Tag> _tagMap = {};

  Client? clientById(int id) => _clientMap[id];
  Tag? tagById(int id) => _tagMap[id];
  PlanTemplate? templateById(int id) => _templateMap[id];

  // ─── UI state ───
  bool isLoading = false;
  int activeTabIndex = 0;
  String userName = '';
  String? _loadError;
  String? get loadError => _loadError;

  static const String _prefsKeyUserName = 'user_name';

  // ─── Loads ───
  Future<void> init() async {
    await loadAll();
    await seedIfEmpty();
  }

  Future<void> loadAll() async {
    isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadClients(),
        _loadTemplates(),
        _loadPlans(),
        _loadAttendance(),
        _loadTags(),
        _loadUserName(),
      ]);
    } catch (e) {
      _loadError = e.toString();
      debugPrint('loadAll failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadClients() async {
    clients = await _repository.getAllClients();
    _clientMap
      ..clear()
      ..addAll({for (final c in clients) c.id!: c});
  }

  Future<void> _loadTemplates() async {
    templates = await _repository.getAllTemplates();
    _templateMap
      ..clear()
      ..addAll({for (final t in templates) t.id!: t});
  }

  Future<void> _loadPlans() async {
    plans = await _repository.getAllPlans();
  }

  Future<void> _loadAttendance() async {
    final all = await _repository.getAllAttendance();

    final bestByKey = <String, AttendanceRecord>{};
    final toDelete = <AttendanceRecord>[];

    for (final r in all) {
      final key = '${r.clientId}_${r.date}';
      final existing = bestByKey[key];
      if (existing == null) {
        bestByKey[key] = r;
      } else {
        final existingScore = existing.status == 'present' ? 1 : 0;
        final newScore = r.status == 'present' ? 1 : 0;
        if (newScore > existingScore ||
            (newScore == existingScore &&
                (r.id ?? 0) > (existing.id ?? 0))) {
          final merged = r.copyWith(sessions: r.sessions + existing.sessions);
          bestByKey[key] = merged;
          toDelete.add(existing);
        } else {
          final merged = existing.copyWith(sessions: existing.sessions + r.sessions);
          bestByKey[key] = merged;
          toDelete.add(r);
        }
      }
    }

    for (final r in toDelete) {
      if (r.id != null) await _repository.deleteAttendance(r.id!);
    }

    attendance = bestByKey.values.toList();
  }

  Future<void> _loadTags() async {
    tags = await _repository.getAllTags();
    _tagMap
      ..clear()
      ..addAll({for (final t in tags) t.id!: t});
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString(_prefsKeyUserName) ?? '';
  }

  // ─── Simple setters ───
  void setTabIndex(int index) {
    if (activeTabIndex == index) return;
    activeTabIndex = index;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    userName = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyUserName, userName);
    notifyListeners();
  }

  // ─── Convenience getters ───
  List<ClientPlan> plansForClient(int clientId) =>
      plans.where((p) => p.clientId == clientId).toList();

  ClientPlan? activePlanForClient(int clientId) {
    for (final p in plans) {
      if (p.clientId == clientId &&
          (p.status == 'active' || p.status == 'frozen')) {
        return p;
      }
    }
    return null;
  }

  List<ClientPlan> queuedPlansForClient(int clientId) {
    final q = plans
        .where((p) => p.clientId == clientId && p.status == 'queued')
        .toList()
      ..sort((a, b) => (a.queueOrder ?? 0).compareTo(b.queueOrder ?? 0));
    return q;
  }

  List<AttendanceRecord> attendanceForClient(int clientId) =>
      attendance.where((a) => a.clientId == clientId).toList();

  List<Tag> tagsForClient(Client client) =>
      client.tagIds.map(tagById).whereType<Tag>().toList();

  // ═══════════════ Client mutations ═══════════════

  Future<int> addClient(Client client) async {
    final id = await _repository.insertClient(client);
    clients.add(client.copyWith(id: id));
    _clientMap[id] = client.copyWith(id: id);
    notifyListeners();
    return id;
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) return;
    await _repository.updateClient(client);
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx != -1) {
      clients[idx] = client;
      _clientMap[client.id!] = client;
    }
    notifyListeners();
  }

  Future<void> deleteClient(int clientId) async {
    await _repository.deleteClientCascade(clientId);
    clients.removeWhere((c) => c.id == clientId);
    _clientMap.remove(clientId);
    plans.removeWhere((p) => p.clientId == clientId);
    attendance.removeWhere((a) => a.clientId == clientId);
    notifyListeners();
  }

  Future<void> adjustBonus(int clientId, int delta) async {
    final idx = clients.indexWhere((c) => c.id == clientId);
    if (idx == -1) return;
    final current = clients[idx];
    final next = current.bonusSessions + delta;
    if (next < 0) return;
    final updated = current.copyWith(bonusSessions: next);
    clients[idx] = updated;
    _clientMap[clientId] = updated;
    await _repository.updateClient(updated);
    notifyListeners();
  }

  // ═══════════════ Tag mutations ═══════════════

  Future<void> addTag(Tag tag) async {
    final id = await _repository.insertTag(tag);
    tags.add(tag.copyWith(id: id));
    _tagMap[id] = tag.copyWith(id: id);
    notifyListeners();
  }

  Future<void> deleteTag(int tagId) async {
    await _repository.deleteTag(tagId);
    tags.removeWhere((t) => t.id == tagId);
    _tagMap.remove(tagId);
    // Strip this tagId from all clients that referenced it
    final futures = <Future>[];
    for (int i = 0; i < clients.length; i++) {
      final c = clients[i];
      if (c.tagIds.contains(tagId)) {
        final updated =
            c.copyWith(tagIds: c.tagIds.where((id) => id != tagId).toList());
        clients[i] = updated;
        _clientMap[updated.id!] = updated;
        futures.add(_repository.updateClient(updated));
      }
    }
    await Future.wait(futures);
    notifyListeners();
  }

  // ═══════════════ Template mutations ═══════════════

  Future<void> addTemplate(PlanTemplate template) async {
    final id = await _repository.insertTemplate(template);
    templates.add(template.copyWith(id: id));
    _templateMap[id] = template.copyWith(id: id);
    notifyListeners();
  }

  /// Updates a template AND propagates the new sessions/days to every
  /// plan that uses it and is currently active or frozen.
  ///
  /// Preserves the number of sessions already used:
  ///   used    = oldSessions - oldRemaining
  ///   newRem  = max(0, newSessions - used)
  Future<void> updateTemplate(PlanTemplate template) async {
    if (template.id == null) return;

    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx == -1) return;
    final old = templates[idx];
    templates[idx] = template;
    _templateMap[template.id!] = template;
    await _repository.updateTemplate(template);

    // Propagate to affected plans
    for (int i = 0; i < plans.length; i++) {
      final p = plans[i];
      if (p.templateId != template.id) continue;
      if (p.status != 'active' && p.status != 'frozen') continue;

      final used = old.sessions - p.remaining;
      final newRemaining =
          (template.sessions - used).clamp(0, template.sessions);

      final updated = p.copyWith(
        sessions: template.sessions,
        days: template.days,
        remaining: newRemaining,
      );
      plans[i] = updated;
      await _repository.updatePlan(updated);
    }

    notifyListeners();
  }

  /// Deletes the template but does NOT delete or modify the plans that
  /// reference it. Existing plans keep working with their stored
  /// sessions/days values.
  Future<void> deleteTemplate(int templateId) async {
    await _repository.deleteTemplate(templateId);
    templates.removeWhere((t) => t.id == templateId);
    _templateMap.remove(templateId);
    notifyListeners();
  }

  // ═══════════════ Plan mutations ═══════════════

  /// Adds a plan for a client.
  ///
  /// If the client already has an active (or frozen) plan, the new plan
  /// is created with status 'queued' and queueOrder = lastOrder + 1.
  /// Otherwise the plan is created with status 'active'.
  ///
  /// Returns the id of the newly created plan.
  Future<int?> addPlan({
    required int clientId,
    required int templateId,
    required String startDate,
  }) async {
    final template = templateById(templateId);
    if (template == null) return null;

    final active = activePlanForClient(clientId);

    if (active != null) {
      // Queue it
      final queue = queuedPlansForClient(clientId);
      final nextOrder = queue.isEmpty
          ? 1
          : (queue.last.queueOrder ?? queue.length) + 1;

      final queued = ClientPlan(
        clientId: clientId,
        templateId: templateId,
        startDate: null,
        sessions: template.sessions,
        days: template.days,
        remaining: template.sessions,
        status: 'queued',
        queueOrder: nextOrder,
      );
      final id = await _repository.insertPlan(queued);
      plans.add(queued.copyWith(id: id));
      notifyListeners();
      return id;
    } else {
      // Create active
      final parsed = jc.JalaliDate.tryParse(startDate);
      final today = jc.JalaliDate.today();

      int elapsedDays = 0;
      if (parsed != null) {
        final start = parsed;
        final isPast = start.year < today.year ||
            (start.year == today.year && start.month < today.month) ||
            (start.year == today.year &&
                start.month == today.month &&
                start.day < today.day);
        
        if (isPast) {
          final startJdn = start.toJdn();
          final todayJdn = today.toJdn();
          elapsedDays = (todayJdn - startJdn).clamp(0, template.days);
        }
      }

      final remainingDays = (template.days - elapsedDays).clamp(0, template.days);

      final plan = ClientPlan(
        clientId: clientId,
        templateId: templateId,
        startDate: startDate,
        sessions: template.sessions,
        days: remainingDays,
        remaining: template.sessions,
        status: 'active',
      );
      final id = await _repository.insertPlan(plan);
      plans.add(plan.copyWith(id: id));
      notifyListeners();
      return id;
    }
  }

  Future<void> deletePlan(int planId) async {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final removed = plans[idx];
    plans.removeAt(idx);
    await _repository.deletePlan(planId);

    // NOTE: We intentionally do NOT delete attendance records when a plan is deleted.
    // Attendance history is preserved for reporting and historical accuracy.

    // If it was active/frozen, promote the first queued plan (if any)
    if (removed.status == 'active' || removed.status == 'frozen') {
      await _promoteNextQueued(removed.clientId);
    }

    await _renumberQueue(removed.clientId);
    notifyListeners();
  }

  Future<void> freezePlan(int planId) async {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final updated = plans[idx].copyWith(status: 'frozen');
    plans[idx] = updated;
    await _repository.updatePlan(updated);
    notifyListeners();
  }

  Future<void> unfreezePlan(int planId) async {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final updated = plans[idx].copyWith(status: 'active');
    plans[idx] = updated;
    await _repository.updatePlan(updated);
    notifyListeners();
  }

  /// Updates attendance records for a client by diffing against the
  /// provided [dateSessionsMap]. Only adds/removes/updates the records
  /// that actually changed, instead of deleting and reinserting
  /// everything.
  ///
  /// The map key is the Jalali date string, and the value is the number
  /// of sessions for that date. A value of 0 means the date is removed.
  Future<void> replaceAttendance(
    int clientId,
    Map<String, int> dateSessionsMap,
  ) async {
    // 1. Snapshot old records keyed by date
    final oldMap = <String, AttendanceRecord>{};
    for (final a in attendance.where((a) => a.clientId == clientId)) {
      oldMap[a.date] = a;
    }

    // 2. Compute delta in total sessions
    int delta = 0;
    for (final entry in dateSessionsMap.entries) {
      final old = oldMap[entry.key];
      final newSessions = entry.value;
      if (old == null) {
        delta += newSessions;
      } else if (newSessions == 0) {
        delta -= old.sessions;
      } else {
        delta += newSessions - old.sessions;
      }
    }

    // 3. Diff: delete removed, insert new, update changed
    final toDelete = <AttendanceRecord>[];
    final toInsert = <MapEntry<String, int>>[];
    final toUpdate = <MapEntry<String, int>>[];

    for (final entry in dateSessionsMap.entries) {
      final old = oldMap[entry.key];
      final newSessions = entry.value;
      if (old == null) {
        // New record
        if (newSessions > 0) toInsert.add(entry);
      } else if (newSessions == 0) {
        // Removed record
        toDelete.add(old);
      } else if (old.sessions != newSessions || old.status != 'present') {
        // Changed record
        toUpdate.add(entry);
      }
    }

    // 4. Apply deletions
    for (final r in toDelete) {
      if (r.id != null) await _repository.deleteAttendance(r.id!);
      attendance.remove(r);
    }

    // 5. Apply updates (delete old, insert new to keep behavior simple)
    for (final entry in toUpdate) {
      final old = oldMap[entry.key]!;
      if (old.id != null) await _repository.deleteAttendance(old.id!);
      attendance.remove(old);
      final rec = AttendanceRecord(
        clientId: clientId,
        date: entry.key,
        status: 'present',
        sessions: entry.value,
      );
      final id = await _repository.insertAttendance(rec);
      attendance.add(rec.copyWith(id: id));
    }

    // 6. Apply insertions
    for (final entry in toInsert) {
      final rec = AttendanceRecord(
        clientId: clientId,
        date: entry.key,
        status: 'present',
        sessions: entry.value,
      );
      final id = await _repository.insertAttendance(rec);
      attendance.add(rec.copyWith(id: id));
    }

    // 7. Adjust the active plan's remaining by the delta
    if (delta != 0) {
      final active = activePlanForClient(clientId);
      if (active != null) {
        final newRemaining =
            (active.remaining - delta).clamp(0, active.sessions);
        final updated = active.copyWith(remaining: newRemaining);
        final idx = plans.indexWhere((p) => p.id == active.id);
        if (idx != -1) plans[idx] = updated;
        await _repository.updatePlan(updated);

        // 8. If this caused the plan to hit 0, promote queued plan
        await _checkProgression(clientId);
      } else {
        // No active plan: adjust bonus for present dates added/removed.
        int bonusDelta = 0;
        for (final entry in dateSessionsMap.entries) {
          final old = oldMap[entry.key];
          final newSessions = entry.value;
          if (old == null && newSessions > 0) {
            bonusDelta -= newSessions;
          } else if (old != null && newSessions == 0) {
            bonusDelta += old.sessions;
          } else if (old != null && newSessions > 0) {
            bonusDelta += old.sessions - newSessions;
          }
        }
        if (bonusDelta != 0) {
          await adjustBonus(clientId, bonusDelta);
        }
      }
    }

    notifyListeners();
  }

  // ═══════════════ Attendance mutations ═══════════════

  /// Marks attendance for a client on a specific date.
  ///
  /// Both 'present' and 'absent' charge the plan (remaining--).
  /// If remaining is already 0 and status is 'present', uses a bonus session.
  /// Then runs checkProgression() which may activate a queued plan.
  Future<void> markAttendance(
    int clientId,
    String status,
    String todayJalali, {
    int sessions = 1,
  }) async {
    final existing = attendance
        .where((a) => a.clientId == clientId && a.date == todayJalali)
        .toList();
    for (final r in existing) {
      if (r.id != null) await _repository.deleteAttendance(r.id!);
    }
    attendance.removeWhere((a) => a.clientId == clientId && a.date == todayJalali);

    final rec = AttendanceRecord(
      clientId: clientId,
      date: todayJalali,
      status: status,
      sessions: sessions,
    );
    final id = await _repository.insertAttendance(rec);
    attendance.add(rec.copyWith(id: id));

    // Charge the plan
    final active = activePlanForClient(clientId);
    if (active != null && active.remaining > 0) {
      final updated = active.copyWith(remaining: active.remaining - sessions);
      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) plans[idx] = updated;
      await _repository.updatePlan(updated);
    } else if (active == null || active.remaining <= 0) {
      if (status == 'present') {
        await adjustBonus(clientId, -sessions);
      }
    }

    await _checkProgression(clientId);
    notifyListeners();
  }

  /// Removes one session from the attendance record for the client on the
  /// given date and refunds 1 session back to the active plan (or bonus).
  /// If the record has only 1 session, it is deleted entirely.
  Future<void> undoAttendance(int clientId, String todayJalali) async {
    final existing = attendance
        .where((a) => a.clientId == clientId && a.date == todayJalali)
        .toList();
    if (existing.isEmpty) return;

    final record = existing.first;
    final currentSessions = record.sessions;

    if (currentSessions <= 1) {
      // Delete the record entirely
      if (record.id != null) await _repository.deleteAttendance(record.id!);
      attendance.remove(record);
    } else {
      // Decrement sessions
      final updated = record.copyWith(sessions: currentSessions - 1);
      if (record.id != null) {
        await _repository.deleteAttendance(record.id!);
        final newId = await _repository.insertAttendance(updated);
        attendance[attendance.indexOf(record)] = updated.copyWith(id: newId);
      } else {
        attendance[attendance.indexOf(record)] = updated;
      }
    }

    // Refund 1 session
    final active = activePlanForClient(clientId);
    if (active != null) {
      final updatedPlan = active.copyWith(remaining: (active.remaining + 1).clamp(0, active.sessions));
      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) plans[idx] = updatedPlan;
      await _repository.updatePlan(updatedPlan);
    } else {
      await adjustBonus(clientId, 1);
    }

    notifyListeners();
  }

  /// Adds one more session to an existing attendance record for the given
  /// date. If no record exists, creates one with 1 session.
  Future<void> addAttendanceSession(int clientId, String date) async {
    final existing = attendance
        .where((a) => a.clientId == clientId && a.date == date)
        .toList();

    if (existing.isEmpty) {
      // Create new record with 1 session
      final rec = AttendanceRecord(
        clientId: clientId,
        date: date,
        status: 'present',
        sessions: 1,
      );
      final id = await _repository.insertAttendance(rec);
      attendance.add(rec.copyWith(id: id));

      // Charge plan
      final active = activePlanForClient(clientId);
      if (active != null && active.remaining > 0) {
        final updated = active.copyWith(remaining: active.remaining - 1);
        final idx = plans.indexWhere((p) => p.id == active.id);
        if (idx != -1) plans[idx] = updated;
        await _repository.updatePlan(updated);
      } else if (active == null || active.remaining <= 0) {
        await adjustBonus(clientId, -1);
      }
    } else {
      // Increment sessions
      final record = existing.first;
      final updated = record.copyWith(sessions: record.sessions + 1);
      if (record.id != null) {
        await _repository.deleteAttendance(record.id!);
        final newId = await _repository.insertAttendance(updated);
        attendance[attendance.indexOf(record)] = updated.copyWith(id: newId);
      } else {
        attendance[attendance.indexOf(record)] = updated;
      }

      // Charge plan
      final active = activePlanForClient(clientId);
      if (active != null && active.remaining > 0) {
        final updatedPlan = active.copyWith(remaining: active.remaining - 1);
        final idx = plans.indexWhere((p) => p.id == active.id);
        if (idx != -1) plans[idx] = updatedPlan;
        await _repository.updatePlan(updatedPlan);
      } else if (active == null || active.remaining <= 0) {
        await adjustBonus(clientId, -1);
      }
    }

    notifyListeners();
  }

  // ═══════════════ Internal helpers ═══════════════

  /// If a client's active plan has 0 sessions left, mark it expired and
  /// promote the first queued plan to active (using today's date).
  Future<void> _checkProgression(int clientId) async {
    final active = activePlanForClient(clientId);
    if (active == null) return;
    if (active.isFrozen) return;

    if (active.remaining <= 0) {
      final queue = queuedPlansForClient(clientId);
      if (queue.isEmpty) return;

      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) {
        final expired = plans[idx].copyWith(status: 'expired');
        plans[idx] = expired;
        await _repository.updatePlan(expired);
      }
      await _promoteNextQueued(clientId);
    }
  }

  Future<void> _promoteNextQueued(int clientId) async {
    final queue = queuedPlansForClient(clientId);
    if (queue.isEmpty) return;

    final next = queue.first;
    final idx = plans.indexWhere((p) => p.id == next.id);
    if (idx == -1) return;

    final promoted = next.copyWith(
      status: 'active',
      startDate: todayJalaliString(),
      remaining: next.sessions,
      clearQueueOrder: true,
    );
    plans[idx] = promoted;
    await _repository.updatePlan(promoted);
  }

  Future<void> _renumberQueue(int clientId) async {
    final queue = queuedPlansForClient(clientId);
    for (int i = 0; i < queue.length; i++) {
      final p = queue[i];
      final newOrder = i + 1;
      if (p.queueOrder == newOrder) continue;
      final idx = plans.indexWhere((x) => x.id == p.id);
      if (idx != -1) {
        final updated = p.copyWith(queueOrder: newOrder);
        plans[idx] = updated;
        await _repository.updatePlan(updated);
      }
    }
  }

  /// Loads initial demo data if the database is completely empty.
  /// Called once on first launch. Safe to call again — it does nothing
  /// if any client already exists.
  Future<void> seedIfEmpty() async {
    if (clients.isNotEmpty ||
        templates.isNotEmpty ||
        plans.isNotEmpty ||
        attendance.isNotEmpty ||
        tags.isNotEmpty) {
      return;
    }

    // ─── Tags ───
    await addTag(const Tag(name: 'باشگاه'));
    await addTag(const Tag(name: 'آنلاین'));
    await addTag(const Tag(name: 'صبح‌ها'));
    await addTag(const Tag(name: 'خصوصی'));
    await addTag(const Tag(name: 'اصلاحی'));

    // Look up their ids
    int tagId(String name) {
      final t = tags.firstWhere((x) => x.name == name,
          orElse: () => throw StateError('tag missing: $name'));
      if (t.id == null) {
        throw StateError('tag has no id: $name');
      }
      return t.id!;
    }

    // ─── Templates ───
    await addTemplate(const PlanTemplate(
        name: 'برنامه ۱۲ جلسه‌ای', sessions: 12, days: 30));
    await addTemplate(const PlanTemplate(
        name: 'برنامه لاغری ۸ جلسه‌ای', sessions: 8, days: 21));
    await addTemplate(const PlanTemplate(
        name: 'برنامه حجم ۱۶ جلسه‌ای', sessions: 16, days: 45));
    await addTemplate(const PlanTemplate(
        name: 'برنامه اصلاحی ۶ جلسه‌ای', sessions: 6, days: 30));

    int templateId(String name) {
      final t = templates.firstWhere((x) => x.name == name,
          orElse: () => throw StateError('template missing: $name'));
      if (t.id == null) {
        throw StateError('template has no id: $name');
      }
      return t.id!;
    }

    // ─── Clients ───
    await addClient(Client(
      name: 'زهرا محمدی',
      contact: '۰۹۱۲ ۳۴۵ ۶۷۸۹',
      tagIds: [tagId('باشگاه'), tagId('صبح‌ها')],
      note: 'پارگی مینیسک',
      bonusSessions: 2,
    ));
    await addClient(Client(
      name: 'سارا احمدی',
      contact: '۰۹۱۳ ۲۲۲ ۳۳۳۳',
      tagIds: [tagId('باشگاه'), tagId('صبح‌ها')],
    ));
    await addClient(Client(
      name: 'مریم رضایی',
      tagIds: [tagId('آنلاین')],
    ));
    await addClient(Client(
      name: 'نگار کریمی',
      contact: '۰۹۱۵ ۸۸۸ ۹۹۹۹',
      tagIds: [tagId('باشگاه'), tagId('خصوصی')],
      note: 'آخر شب تمرین می‌کند',
      bonusSessions: 1,
    ));
    await addClient(Client(
      name: 'الهام نوری',
      tagIds: [tagId('آنلاین'), tagId('اصلاحی')],
      note: 'کمردرد مزمن',
      bonusSessions: 3,
    ));
    await addClient(Client(
      name: 'فاطمه صادقی',
      contact: '۰۹۳۵ ۱۱۱ ۲۲۲۲',
      tagIds: [tagId('باشگاه')],
    ));
    await addClient(Client(
      name: 'رضا محمدی',
      tagIds: [tagId('آنلاین'), tagId('خصوصی')],
    ));
    await addClient(Client(
      name: 'پریسا کریمی',
      contact: '۰۹۱۹ ۷۷۷ ۳۳۳۳',
      tagIds: [tagId('باشگاه'), tagId('صبح‌ها'), tagId('خصوصی')],
      note: 'سطح مبتدی',
    ));

    // Helper to get client by name
    int clientId(String name) {
      final c = clients.firstWhere((x) => x.name == name,
          orElse: () => throw StateError('client missing: $name'));
      if (c.id == null) {
        throw StateError('client has no id: $name');
      }
      return c.id!;
    }

    final today = jc.JalaliDate.today().toString();
    // '۱۴۰۵/۰۶/۲۱' — matches the mockup

    // ─── Plans ───
    // We can't use addPlan here because it auto-queues.
    // Instead we insert directly so we control status.
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('زهرا محمدی'),
      templateId: templateId('برنامه ۱۲ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۵/۱۵',
      sessions: 12,
      days: 30,
      remaining: 9,
      status: 'active',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('زهرا محمدی'),
      templateId: templateId('برنامه حجم ۱۶ جلسه‌ای'),
      startDate: null,
      sessions: 16,
      days: 45,
      remaining: 16,
      status: 'queued',
      queueOrder: 1,
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('سارا احمدی'),
      templateId: templateId('برنامه لاغری ۸ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۶/۰۱',
      sessions: 8,
      days: 21,
      remaining: 3,
      status: 'frozen',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('مریم رضایی'),
      templateId: templateId('برنامه ۱۲ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۴/۲۰',
      sessions: 12,
      days: 30,
      remaining: 0,
      status: 'expired',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('نگار کریمی'),
      templateId: templateId('برنامه حجم ۱۶ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۵/۱۰',
      sessions: 16,
      days: 45,
      remaining: 6,
      status: 'active',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('الهام نوری'),
      templateId: templateId('برنامه اصلاحی ۶ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۵/۲۰',
      sessions: 6,
      days: 30,
      remaining: 2,
      status: 'active',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('فاطمه صادقی'),
      templateId: templateId('برنامه ۱۲ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۴/۱۵',
      sessions: 12,
      days: 30,
      remaining: 0,
      status: 'expired',
    ));
    await _insertPlanDirect(ClientPlan(
      clientId: clientId('پریسا کریمی'),
      templateId: templateId('برنامه لاغری ۸ جلسه‌ای'),
      startDate: '۱۴۰۵/۰۶/۰۵',
      sessions: 8,
      days: 21,
      remaining: 7,
      status: 'active',
    ));

    // ─── Attendance ───
    await _insertAttendanceDirect(
        clientId('زهرا محمدی'), today, 'present');
    await _insertAttendanceDirect(
        clientId('نگار کریمی'), today, 'present');
    await _insertAttendanceDirect(
        clientId('فاطمه صادقی'), today, 'absent');
    await _insertAttendanceDirect(
        clientId('زهرا محمدی'), '۱۴۰۵/۰۶/۲۰', 'present');
    await _insertAttendanceDirect(
        clientId('سارا احمدی'), '۱۴۰۵/۰۶/۲۰', 'absent');
    await _insertAttendanceDirect(
        clientId('زهرا محمدی'), '۱۴۰۵/۰۶/۱۸', 'present');
    await _insertAttendanceDirect(
        clientId('نگار کریمی'), '۱۴۰۵/۰۶/۱۸', 'present');
    await _insertAttendanceDirect(
        clientId('الهام نوری'), '۱۴۰۵/۰۶/۱۷', 'present');
    await _insertAttendanceDirect(
        clientId('زهرا محمدی'), '۱۴۰۵/۰۶/۱۵', 'present');

    notifyListeners();
  }

  // ─── Direct insert helpers (bypass queue logic) ───
  Future<void> _insertPlanDirect(ClientPlan plan) async {
    final id = await _repository.insertPlan(plan);
    plans.add(plan.copyWith(id: id));
  }

  Future<void> _insertAttendanceDirect(
      int clientId, String date, String status) async {
    final rec = AttendanceRecord(
      clientId: clientId,
      date: date,
      status: status,
    );
    final id = await _repository.insertAttendance(rec);
    attendance.add(rec.copyWith(id: id));
  }

  /// Returns today's date as a Jalali string, e.g. '۱۴۰۵/۰۶/۲۱'.
  /// Used when promoting a queued plan to active.
  String todayJalaliString() => jc.JalaliDate.today().toString();

  /// Deletes every record in every store and resets in-memory state.
  Future<void> deleteAllData() async {
    final db = await _repository.database;
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
    clients = [];
    templates = [];
    plans = [];
    attendance = [];
    tags = [];
    _clientMap.clear();
    _templateMap.clear();
    _tagMap.clear();
    notifyListeners();
  }

 }