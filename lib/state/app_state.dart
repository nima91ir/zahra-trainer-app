import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart' as shamsi;

import '../data/database.dart';
import '../data/models/client.dart';
import '../data/models/tag.dart';
import '../data/models/plan_template.dart';
import '../data/models/client_plan.dart';
import '../data/models/attendance_record.dart';
import '../utils/jalali_calendar.dart' as jc;

/// Central app state.
/// Every mutation calls notifyListeners() at the end.
class AppState extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  // ─── Raw data ───
  List<Client> clients = [];
  List<PlanTemplate> templates = [];
  List<ClientPlan> plans = [];
  List<AttendanceRecord> attendance = [];
  List<Tag> tags = [];

  // ─── UI state ───
  bool isLoading = false;
  int activeTabIndex = 0;
  String userName = '';

  static const String _prefsKeyUserName = 'user_name';

  // ─── Loads ───
  Future<void> init() async {
    await loadAll();
    await seedIfEmpty();
  }

  Future<void> loadAll() async {
    isLoading = true;
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
      // Prevent the UI from staying stuck on loading if any store fails.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadClients() async {
    clients = await _db.getAllClients();
  }

  Future<void> _loadTemplates() async {
    templates = await _db.getAllTemplates();
  }

  Future<void> _loadPlans() async {
    plans = await _db.getAllPlans();
  }

  Future<void> _loadAttendance() async {
    attendance = await _db.getAllAttendance();
  }

  Future<void> _loadTags() async {
    tags = await _db.getAllTags();
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
  Client? clientById(int id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  Tag? tagById(int id) {
    for (final t in tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  PlanTemplate? templateById(int id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

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
    final id = await _db.insertClient(client);
    clients.add(client.copyWith(id: id));
    notifyListeners();
    return id;
  }

  Future<void> updateClient(Client client) async {
    if (client.id == null) return;
    await _db.updateClient(client);
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx != -1) clients[idx] = client;
    notifyListeners();
  }

  Future<void> deleteClient(int clientId) async {
    await _db.deleteClientCascade(clientId);
    clients.removeWhere((c) => c.id == clientId);
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
    await _db.updateClient(updated);
    notifyListeners();
  }

  // ═══════════════ Tag mutations ═══════════════

  Future<void> addTag(Tag tag) async {
    final id = await _db.insertTag(tag);
    tags.add(tag.copyWith(id: id));
    notifyListeners();
  }

  Future<void> deleteTag(int tagId) async {
    await _db.deleteTag(tagId);
    tags.removeWhere((t) => t.id == tagId);
    // Strip this tagId from all clients that referenced it
    final futures = <Future>[];
    for (int i = 0; i < clients.length; i++) {
      final c = clients[i];
      if (c.tagIds.contains(tagId)) {
        final updated =
            c.copyWith(tagIds: c.tagIds.where((id) => id != tagId).toList());
        clients[i] = updated;
        futures.add(_db.updateClient(updated));
      }
    }
    await Future.wait(futures);
    notifyListeners();
  }

  // ═══════════════ Template mutations ═══════════════

  Future<void> addTemplate(PlanTemplate template) async {
    final id = await _db.insertTemplate(template);
    templates.add(template.copyWith(id: id));
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
    await _db.updateTemplate(template);

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
      await _db.updatePlan(updated);
    }

    notifyListeners();
  }

  /// Deletes the template but does NOT delete or modify the plans that
  /// reference it. Existing plans keep working with their stored
  /// sessions/days values.
  Future<void> deleteTemplate(int templateId) async {
    await _db.deleteTemplate(templateId);
    templates.removeWhere((t) => t.id == templateId);
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
    print('addPlan: clientId=$clientId, templateId=$templateId, startDate=$startDate');
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
      final id = await _db.insertPlan(queued);
      plans.add(queued.copyWith(id: id));
      notifyListeners();
      return id;
    } else {
      // Create active
      final parsed = jc.JalaliDate.tryParse(startDate);
      final today = jc.JalaliDate.today();
      print('addPlan: parsed=$parsed, today=$today');

      int elapsedDays = 0;
      int pastAttendanceCount = 0;
      if (parsed != null) {
        // Elapsed days between startDate and today (inclusive of start, exclusive of today if past)
        final start = parsed;
        final isPast = start.year < today.year ||
            (start.year == today.year && start.month < today.month) ||
            (start.year == today.year &&
                start.month == today.month &&
                start.day < today.day);
        print('addPlan: isPast=$isPast, start=$start, today=$today');
        
        if (isPast) {
          final startJdn = shamsi.Jalali(start.year, start.month, start.day).julianDayNumber;
          final todayJdn = shamsi.Jalali(today.year, today.month, today.day).julianDayNumber;
          elapsedDays = (todayJdn - startJdn).clamp(0, template.days);

          final normalizedStart = start.toString();
          final normalizedToday = today.toString();
          pastAttendanceCount = attendance
              .where((a) =>
                  a.clientId == clientId &&
                  a.date.compareTo(normalizedStart) >= 0 &&
                  a.date.compareTo(normalizedToday) <= 0 &&
                  (a.status == 'present' || a.status == 'absent'))
              .length;
          print('addPlan: elapsedDays=$elapsedDays, pastAttendanceCount=$pastAttendanceCount');
        }
      }

      final remainingDays = (template.days - elapsedDays).clamp(0, template.days);
      final remainingSessions =
          (template.sessions - pastAttendanceCount).clamp(0, template.sessions);
      print('addPlan: remainingDays=$remainingDays, remainingSessions=$remainingSessions');

      final plan = ClientPlan(
        clientId: clientId,
        templateId: templateId,
        startDate: startDate,
        sessions: template.sessions,
        days: remainingDays,
        remaining: remainingSessions,
        status: 'active',
      );
      final id = await _db.insertPlan(plan);
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
    await _db.deletePlan(planId);

    await _deleteAttendanceForPlan(removed.clientId, removed);

    // If it was active/frozen, promote the first queued plan (if any)
    if (removed.status == 'active' || removed.status == 'frozen') {
      await _promoteNextQueued(removed.clientId);
    }

    await _renumberQueue(removed.clientId);
    notifyListeners();
  }

  Future<void> _deleteAttendanceForPlan(int clientId, ClientPlan plan) async {
    if (plan.startDate == null) return;
    final start = jc.JalaliDate.tryParse(plan.startDate!);
    if (start == null) return;

    final startJdn = shamsi.Jalali(start.year, start.month, start.day).julianDayNumber;
    final template = templateById(plan.templateId);
    final duration = template?.days ?? plan.days;
    final endJdn = startJdn + duration - 1;

    final toDelete = attendance.where((a) {
      if (a.clientId != clientId) return false;
      final date = jc.JalaliDate.tryParse(a.date);
      if (date == null) return false;
      final jdn = shamsi.Jalali(date.year, date.month, date.day).julianDayNumber;
      return jdn >= startJdn && jdn <= endJdn;
    }).toList();

    final toDeleteSet = toDelete.toSet();
    for (final r in toDelete) {
      if (r.id != null) await _db.deleteAttendance(r.id!);
    }
    attendance.removeWhere(toDeleteSet.contains);
  }

  Future<void> freezePlan(int planId) async {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final updated = plans[idx].copyWith(status: 'frozen');
    plans[idx] = updated;
    await _db.updatePlan(updated);
    notifyListeners();
  }

  Future<void> unfreezePlan(int planId) async {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final updated = plans[idx].copyWith(status: 'active');
    plans[idx] = updated;
    await _db.updatePlan(updated);
    notifyListeners();
  }

  /// Deletes ALL attendance records for the client, then writes the new set.
  /// Used by the Past Attendance calendar.
  Future<void> replaceAttendance(
    int clientId,
    Map<String, String> dateStatusMap,
  ) async {
    // 1. Snapshot old statuses so we can compute the delta per date
    final oldStatusMap = <String, String>{};
    for (final a in attendance.where((a) => a.clientId == clientId)) {
      oldStatusMap[a.date] = a.status;
    }

    // 2. Compute delta from per-date changes
    // Both 'present' and 'absent' consume 1 session from the active plan,
    // so only additions/removals of dated records affect plan remaining.
    int delta = 0;
    for (final entry in dateStatusMap.entries) {
      final oldStatus = oldStatusMap[entry.key];
      final newStatus = entry.value;
      if (oldStatus == null) {
        if (newStatus == 'present' || newStatus == 'absent') delta += 1;
      } else if (newStatus.isEmpty) {
        if (oldStatus == 'present' || oldStatus == 'absent') delta -= 1;
      }
    }

    // 3. Delete existing records
    final existing =
        attendance.where((a) => a.clientId == clientId).toList();
    for (final r in existing) {
      if (r.id != null) await _db.deleteAttendance(r.id!);
    }
    attendance.removeWhere((a) => a.clientId == clientId);

    // 4. Insert new records
    for (final entry in dateStatusMap.entries) {
      final rec = AttendanceRecord(
        clientId: clientId,
        date: entry.key,
        status: entry.value,
      );
      final id = await _db.insertAttendance(rec);
      attendance.add(rec.copyWith(id: id));
    }

    // 5. Adjust the active plan's remaining by the delta
    if (delta != 0) {
      final active = activePlanForClient(clientId);
      if (active != null) {
        final newRemaining =
            (active.remaining - delta).clamp(0, active.sessions);
        final updated = active.copyWith(remaining: newRemaining);
        final idx = plans.indexWhere((p) => p.id == active.id);
        if (idx != -1) plans[idx] = updated;
        await _db.updatePlan(updated);

        // 6. If this caused the plan to hit 0, promote queued plan
        await _checkProgression(clientId);
      } else {
        // No active plan: adjust bonus for present dates added/removed.
        int bonusDelta = 0;
        for (final entry in dateStatusMap.entries) {
          final oldStatus = oldStatusMap[entry.key];
          final newStatus = entry.value;
          if (oldStatus == null && newStatus == 'present') {
            bonusDelta -= 1;
          } else if (oldStatus == 'present' &&
              (newStatus.isEmpty || newStatus == 'absent')) {
            bonusDelta += 1;
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

  /// Marks today's attendance for a client.
  ///
  /// Both 'present' and 'absent' charge the plan (remaining--).
  /// If remaining is already 0 and status is 'present', uses a bonus session.
  /// Then runs checkProgression() which may activate a queued plan.
  Future<void> markAttendance(
    int clientId,
    String status,
    String todayJalali,
  ) async {
    // Remove any existing record for today
    final existing = attendance.firstWhere(
      (a) => a.clientId == clientId && a.date == todayJalali,
      orElse: () => const AttendanceRecord(
          clientId: 0, date: '', status: ''),
    );
    if (existing.clientId != 0 && existing.id != null) {
      await _db.deleteAttendance(existing.id!);
      attendance.remove(existing);
    }

    // Insert new record
    final rec = AttendanceRecord(
      clientId: clientId,
      date: todayJalali,
      status: status,
    );
    final id = await _db.insertAttendance(rec);
    attendance.add(rec.copyWith(id: id));

    // Charge the plan
    final active = activePlanForClient(clientId);
    if (active != null && active.remaining > 0) {
      final updated = active.copyWith(remaining: active.remaining - 1);
      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) plans[idx] = updated;
      await _db.updatePlan(updated);
    } else if (active == null || active.remaining <= 0) {
      if (status == 'present') {
        await adjustBonus(clientId, -1);
      }
    }

    await _checkProgression(clientId);
    notifyListeners();
  }

  /// Removes today's attendance record for the client and refunds 1
  /// session back to the active plan (or bonus).
  Future<void> undoAttendance(int clientId, String todayJalali) async {
    final existing = attendance.firstWhere(
      (a) => a.clientId == clientId && a.date == todayJalali,
      orElse: () => const AttendanceRecord(
          clientId: 0, date: '', status: ''),
    );
    if (existing.clientId == 0) return;

    if (existing.id != null) await _db.deleteAttendance(existing.id!);
    attendance.remove(existing);

    // Refund
    final active = activePlanForClient(clientId);
    if (active != null && active.remaining < active.sessions) {
      final updated = active.copyWith(remaining: active.remaining + 1);
      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) plans[idx] = updated;
      await _db.updatePlan(updated);
    } else if (active == null) {
      await adjustBonus(clientId, 1);
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
      final idx = plans.indexWhere((p) => p.id == active.id);
      if (idx != -1) {
        final expired = plans[idx].copyWith(status: 'expired');
        plans[idx] = expired;
        await _db.updatePlan(expired);
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
    await _db.updatePlan(promoted);
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
        await _db.updatePlan(updated);
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
    final id = await _db.insertPlan(plan);
    plans.add(plan.copyWith(id: id));
  }

  Future<void> _insertAttendanceDirect(
      int clientId, String date, String status) async {
    final rec = AttendanceRecord(
      clientId: clientId,
      date: date,
      status: status,
    );
    final id = await _db.insertAttendance(rec);
    attendance.add(rec.copyWith(id: id));
  }

  /// Returns today's date as a Jalali string, e.g. '۱۴۰۵/۰۶/۲۱'.
  /// Used when promoting a queued plan to active.
  String todayJalaliString() => jc.JalaliDate.today().toString();

  /// Deletes every record in every store and resets in-memory state.
  Future<void> deleteAllData() async {
    final db = await _db.database;
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
    notifyListeners();
  }

 }