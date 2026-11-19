import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';
import 'models.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class TimelineEntry {
  TimelineEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.odo,
    this.cost,
  });
  final String kind; // 'service' | 'fuel'
  final int id;
  final String title;
  final String subtitle;
  final DateTime date;
  final int odo;
  final double? cost;
}

class FuelInterval {
  FuelInterval({
    required this.log,
    required this.isBaseline,
    required this.km,
    required this.kmPerLiter,
    required this.counts,
  });
  final FuelLog log;
  final bool isBaseline;

  /// TRIP B distance for this interval (null for baseline / missing).
  final double? km;

  /// Null unless this is a valid full-to-full interval.
  final double? kmPerLiter;
  final bool counts;
}

class MonthSpend {
  MonthSpend(this.month, this.service, this.fuel);
  final DateTime month;
  final double service;
  final double fuel;
  double get total => service + fuel;
}

class AppState extends ChangeNotifier {
  AppState(this._db, this._notifs, this._sync);

  final AppDb _db;
  final NotificationService _notifs;
  final SyncService _sync;

  List<Vehicle> vehicles = [];
  Vehicle? active;
  List<ServiceItem> items = [];
  List<ServiceLog> logs = [];
  List<FuelLog> fuel = [];
  List<OdoReading> readings = [];
  bool remindersOn = true;
  ThemeMode themeMode = ThemeMode.system;

  SyncService get sync => _sync;

  // ───────────── loading ─────────────

  Future<void> load() async {
    remindersOn = (await _db.getSetting('reminders')) != '0';
    themeMode = switch (await _db.getSetting('theme')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final saved = int.tryParse(await _db.getSetting('active_vehicle') ?? '');
    vehicles = await _db.vehicles();
    active = vehicles.isEmpty
        ? null
        : vehicles.firstWhere((v) => v.id == saved, orElse: () => vehicles.first);
    await _loadVehicleData();
    notifyListeners();
    await reschedule();
  }

  Future<void> _loadVehicleData() async {
    final v = active;
    if (v == null) {
      items = [];
      logs = [];
      fuel = [];
      readings = [];
      return;
    }
    items = await _db.items(v.id!);
    logs = await _db.logs(v.id!);
    fuel = await _db.fuel(v.id!);
    readings = await _db.readings(v.id!);
  }

  Future<void> _reloadAll() async {
    final id = active?.id;
    vehicles = await _db.vehicles();
    active = vehicles.isEmpty ? null : vehicles.firstWhere((v) => v.id == id, orElse: () => vehicles.first);
    if (active != null) await _db.setSetting('active_vehicle', '${active!.id}');
    await _loadVehicleData();
    notifyListeners();
    await reschedule();
    unawaited(_sync.syncNow());
  }

  // ───────────── vehicles ─────────────

  Future<void> createVehicle(Vehicle v, List<ServiceItem> startItems) async {
    final id = await _db.insertVehicle(v);
    await _db.insertReading(OdoReading(vehicleId: id, odo: v.odo, date: DateTime.now()));
    for (final it in startItems) {
      await _db.insertItem(it.copyWith(vehicleId: id));
    }
    active = v.copyWith(id: id);
    await _reloadAll();
  }

  Future<void> selectVehicle(Vehicle v) async {
    active = v;
    await _reloadAll();
  }

  Future<void> updateVehicle(Vehicle v) async {
    await _db.updateVehicle(v);
    await _reloadAll();
  }

  Future<void> deleteVehicle(Vehicle v) async {
    await _db.deleteVehicle(v.id!);
    if (active?.id == v.id) active = null;
    await _reloadAll();
  }

  // ───────────── odometer ─────────────

  Future<void> _applyOdo(int odo, DateTime date) async {
    final v = active!;
    if (odo > v.odo) {
      await _db.updateVehicle(v.copyWith(odo: odo, odoUpdatedAt: date));
    }
    await _db.insertReading(OdoReading(vehicleId: v.id!, odo: odo, date: date));
  }

  Future<void> updateOdo(int odo) async {
    await _applyOdo(odo, DateTime.now());
    await _reloadAll();
  }

  // ───────────── logs ─────────────

  Future<void> logService({
    required List<ServiceItem> done,
    String extraTitle = '',
    required int odo,
    required DateTime date,
    double? cost,
    String shop = '',
    String notes = '',
  }) async {
    final v = active!;
    final names = [...done.map((e) => e.name), if (extraTitle.trim().isNotEmpty) extraTitle.trim()];
    await _db.insertLog(ServiceLog(
      vehicleId: v.id!,
      itemIds: done.map((e) => e.id!).toList(),
      title: names.join(', '),
      odo: odo,
      date: date,
      cost: cost,
      shop: shop,
      notes: notes,
    ));
    for (final it in done) {
      // Only move "last done" forward, never back (in case an old service is logged late).
      if (it.lastOdo == null || odo >= it.lastOdo!) {
        await _db.updateItem(it.copyWith(lastOdo: odo, lastDate: date));
      }
    }
    await _applyOdo(odo, date);
    await _reloadAll();
  }

  /// [odo] is the bike's total odometer (drives maintenance). [tripKm] is the TRIP B
  /// distance since the previous refill (drives fuel economy). They are stored
  /// separately and never derived from each other.
  Future<void> addFuel({
    required int odo,
    required DateTime date,
    required double liters,
    required double totalCost,
    double? tripKm,
    bool fullTank = true,
  }) async {
    await _db.insertFuel(FuelLog(
      vehicleId: active!.id!,
      odo: odo,
      date: date,
      liters: liters,
      totalCost: totalCost,
      tripKm: (tripKm != null && tripKm > 0) ? tripKm : null,
      fullTank: fullTank,
    ));
    await _applyOdo(odo, date);
    await _reloadAll();
  }

  Future<void> deleteTimelineEntry(TimelineEntry e) async {
    if (e.kind == 'fuel') {
      await _db.deleteFuel(e.id);
    } else {
      await _db.deleteLog(e.id);
    }
    await _reloadAll();
  }

  // ───────────── reminder items ─────────────

  Future<void> saveItem(ServiceItem it) async {
    if (it.id == null) {
      await _db.insertItem(it);
    } else {
      await _db.updateItem(it);
    }
    await _reloadAll();
  }

  Future<void> deleteItem(ServiceItem it) async {
    await _db.deleteItem(it.id!);
    await _reloadAll();
  }

  // ───────────── derived data ─────────────

  /// Riding pace: measured from your last 90 days of ODO updates when there is
  /// enough data, otherwise the estimate you gave for the vehicle.
  double get kmPerDay {
    final v = active;
    if (v == null) return 15;
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final rs = readings.where((r) => r.date.isAfter(cutoff)).toList();
    if (rs.length >= 2) {
      final days = rs.last.date.difference(rs.first.date).inDays;
      if (days >= 7) {
        final rate = (rs.last.odo - rs.first.odo) / days;
        if (rate > 0) return rate.clamp(1.0, 400.0).toDouble();
      }
    }
    return v.avgKmPerDay;
  }

  bool get kmPerDayIsMeasured {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final rs = readings.where((r) => r.date.isAfter(cutoff)).toList();
    return rs.length >= 2 && rs.last.date.difference(rs.first.date).inDays >= 7;
  }

  DueInfo dueFor(ServiceItem it) => computeDue(it, active!.odo, kmPerDay, DateTime.now());

  /// Enabled items, most urgent first.
  List<MapEntry<ServiceItem, DueInfo>> get ranked {
    if (active == null) return [];
    final list = items.where((i) => i.enabled).map((i) => MapEntry(i, dueFor(i))).toList();
    int rank(DueState s) => switch (s) {
          DueState.overdue => 0,
          DueState.soon => 1,
          DueState.ok => 2,
          DueState.unknown => 3,
        };
    list.sort((a, b) {
      final r = rank(a.value.state).compareTo(rank(b.value.state));
      return r != 0 ? r : a.value.urgentDays.compareTo(b.value.urgentDays);
    });
    return list;
  }

  List<TimelineEntry> get timeline {
    final byId = {for (final i in fuelIntervals) i.log.id: i};
    final out = <TimelineEntry>[
      for (final l in logs)
        TimelineEntry(
          kind: 'service',
          id: l.id!,
          title: l.title,
          subtitle: [fmtKm(l.odo), if (l.shop.isNotEmpty) l.shop].join(' · '),
          date: l.date,
          odo: l.odo,
          cost: l.cost,
        ),
      for (final f in fuel)
        TimelineEntry(
          kind: 'fuel',
          id: f.id!,
          title: 'Fuel · ${f.liters.toStringAsFixed(2)} L',
          subtitle: _fuelSubtitle(f, byId[f.id]),
          date: f.date,
          odo: f.odo,
          cost: f.totalCost,
        ),
    ];
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  double get totalServiceCost => logs.fold(0.0, (s, l) => s + (l.cost ?? 0));
  double get totalFuelCost => fuel.fold(0.0, (s, f) => s + f.totalCost);

  // ───────────── fuel economy (TRIP B based) ─────────────

  /// Fuel entries oldest → newest, with per-entry TRIP B distance and km/L.
  /// km/L = TRIP B distance ÷ liters, and only when it is a valid full-to-full interval:
  ///  • not the first (baseline) entry,
  ///  • TRIP B > 0 and liters > 0,
  ///  • this fill AND the previous fill were filled to full.
  /// ODO differences are never used here.
  List<FuelInterval> get fuelIntervals {
    final asc = [...fuel]..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    final out = <FuelInterval>[];
    for (var i = 0; i < asc.length; i++) {
      final f = asc[i];
      final prev = i > 0 ? asc[i - 1] : null;
      final km = (prev != null && f.tripKm != null && f.tripKm! > 0) ? f.tripKm : null;
      final valid = km != null && f.liters > 0 && f.fullTank && prev!.fullTank;
      out.add(FuelInterval(
        log: f,
        isBaseline: prev == null,
        km: km,
        kmPerLiter: valid ? km! / f.liters : null,
        counts: valid,
      ));
    }
    return out;
  }

  String _fuelSubtitle(FuelLog f, FuelInterval? iv) {
    String n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return [
      fmtKm(f.odo),
      '₱${f.pricePerLiter.toStringAsFixed(2)}/L',
      if (iv != null && iv.isBaseline)
        'baseline fill'
      else if (iv?.km != null)
        '${n(iv!.km!)} km TRIP B',
      if (iv?.kmPerLiter != null)
        '${iv!.kmPerLiter!.toStringAsFixed(1)} km/L'
      else if (iv != null && !iv.isBaseline && iv.km != null && !f.fullTank)
        'partial fill'
      else if (iv != null && !iv.isBaseline && iv.km == null)
        'no TRIP B',
    ].join(' · ');
  }

  /// Number of fill-ups that produced a valid km/L.
  int get fuelEconomySamples => fuelIntervals.where((i) => i.counts).length;

  /// Average km/L over all valid full-to-full intervals (total TRIP B km ÷ total liters).
  double? get kmPerLiter {
    final v = fuelIntervals.where((i) => i.counts).toList();
    final km = v.fold(0.0, (s, i) => s + i.km!);
    final liters = v.fold(0.0, (s, i) => s + i.log.liters);
    if (v.isEmpty || km <= 0 || liters <= 0) return null;
    return km / liters;
  }

  /// Fuel spend per km, from the same valid intervals as [kmPerLiter].
  double? get fuelCostPerKm {
    final v = fuelIntervals.where((i) => i.counts).toList();
    final km = v.fold(0.0, (s, i) => s + i.km!);
    final cost = v.fold(0.0, (s, i) => s + i.log.totalCost);
    if (v.isEmpty || km <= 0 || cost <= 0) return null;
    return cost / km;
  }

  /// Distance between the lowest and highest recorded ODO. Order-independent, so a
  /// backdated entry or a typo can no longer produce a negative number.
  int get kmTracked {
    if (readings.length < 2) return 0;
    var lo = readings.first.odo, hi = readings.first.odo;
    for (final r in readings) {
      if (r.odo < lo) lo = r.odo;
      if (r.odo > hi) hi = r.odo;
    }
    return hi - lo;
  }

  double get thisMonthSpend {
    final now = DateTime.now();
    bool same(DateTime d) => d.year == now.year && d.month == now.month;
    return logs.where((l) => same(l.date)).fold(0.0, (s, l) => s + (l.cost ?? 0)) +
        fuel.where((f) => same(f.date)).fold(0.0, (s, f) => s + f.totalCost);
  }

  List<MonthSpend> monthlySpend({int months = 6}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final m = DateTime(now.year, now.month - (months - 1 - i), 1);
      bool same(DateTime d) => d.year == m.year && d.month == m.month;
      return MonthSpend(
        m,
        logs.where((l) => same(l.date)).fold(0.0, (s, l) => s + (l.cost ?? 0)),
        fuel.where((f) => same(f.date)).fold(0.0, (s, f) => s + f.totalCost),
      );
    });
  }

  // ───────────── reminders (local notifications) ─────────────

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await _db.setSetting('theme', m.name);
    notifyListeners();
  }

  Future<void> setReminders(bool on) async {
    remindersOn = on;
    await _db.setSetting('reminders', on ? '1' : '0');
    if (on) await _notifs.requestPermission();
    notifyListeners();
    await reschedule();
  }

  DateTime _nextAt(int hour, DateTime from) {
    var d = DateTime(from.year, from.month, from.day, hour);
    if (!d.isAfter(from)) d = d.add(const Duration(days: 1));
    return d;
  }

  /// Notifications can't watch your odometer, so we project each item's due date
  /// from your riding pace and schedule a heads-up a week before.
  /// Every time you update the ODO or log a service, the plan is rebuilt.
  Future<void> reschedule() async {
    await _notifs.cancelAll();
    final v = active;
    if (!remindersOn || v == null) return;
    final now = DateTime.now();
    final tomorrow9 = _nextAt(9, now);

    // Weekly nudge so the km-based estimates stay accurate.
    var sunday = DateTime(now.year, now.month, now.day, 18);
    while (sunday.weekday != DateTime.sunday || !sunday.isAfter(now)) {
      sunday = sunday.add(const Duration(days: 1));
    }
    await _notifs.schedule(
      id: 1,
      title: 'Odometer check-in',
      body: 'Update your ODO so ${v.name} reminders stay accurate.',
      when: sunday,
      weekly: true,
    );

    for (final e in ranked) {
      final it = e.key;
      final info = e.value;
      if (info.state == DueState.unknown || it.id == null) continue;
      final id = 1000 + it.id!;
      if (info.state == DueState.overdue) {
        await _notifs.schedule(
          id: id,
          title: '${it.name} is overdue',
          body: '${info.label} — ${v.name}',
          when: tomorrow9,
          weekly: true,
        );
      } else {
        var when = _nextAt(9, info.estimatedDue!.subtract(const Duration(days: 7)));
        if (when.isBefore(tomorrow9)) when = tomorrow9;
        final dueText = info.estimatedDue == null ? '' : ' (around ${DateFormat('d MMM').format(info.estimatedDue!)})';
        await _notifs.schedule(
          id: id,
          title: '${it.name} coming up',
          body: '${info.label}$dueText — ${v.name}',
          when: when,
        );
      }
    }
  }

  // ───────────── backup ─────────────

  /// Replaces everything with a backup file's contents. Throws [FormatException]
  /// if the text isn't a valid MotoLog backup (nothing is changed in that case).
  Future<void> importBackup(String text) async {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('Not a MotoLog backup');
    await _db.restore(Map<String, dynamic>.from(decoded));
    await load();
  }

  Future<void> exportBackup() async {
    final data = await _db.dump();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/motolog_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'MotoLog backup'),
    );
  }

}
