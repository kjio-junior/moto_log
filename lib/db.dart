import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Plain local storage: everything lives in one JSON file in the app's private
/// documents folder (no database). It is loaded into memory on start and written
/// back after every change, so the app works fully offline.
class AppDb {
  AppDb._(this._file, this._data);

  final File _file;
  Map<String, dynamic> _data;

  static const _tables = [
    'vehicles',
    'service_items',
    'service_logs',
    'fuel_logs',
    'odo_readings',
  ];

  static Future<AppDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}motolog_data.json');
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map);
      } catch (_) {
        // Unreadable file: keep a copy instead of silently overwriting it.
        await file.copy('${file.path}.corrupt');
      }
    }
    final db = AppDb._(file, data);
    db._normalize();
    return db;
  }

  void _normalize() {
    for (final t in _tables) {
      final raw = _data[t];
      _data[t] = raw is List
          ? [for (final r in raw) Map<String, Object?>.from(r as Map)]
          : <Map<String, Object?>>[];
    }
    _data['settings'] = _data['settings'] is Map
        ? Map<String, dynamic>.from(_data['settings'] as Map)
        : <String, dynamic>{};
    final seq = <String, dynamic>{};
    for (final t in _tables) {
      var maxId = 0;
      for (final r in _rows(t)) {
        final id = r['id'];
        if (id is int && id > maxId) maxId = id;
      }
      seq[t] = maxId;
    }
    _data['seq'] = seq;
  }

  List<Map<String, Object?>> _rows(String t) => (_data[t] as List).cast<Map<String, Object?>>();

  Future<void> _save() async {
    await _file.writeAsString(jsonEncode(_data), flush: true);
  }

  Future<int> _insert(String t, Map<String, Object?> m) async {
    final seq = _data['seq'] as Map<String, dynamic>;
    final id = (seq[t] as int) + 1;
    seq[t] = id;
    _rows(t).add({...m, 'id': id});
    await _save();
    return id;
  }

  Future<void> _update(String t, int? id, Map<String, Object?> m) async {
    final rows = _rows(t);
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i >= 0) rows[i] = {...m, 'id': id};
    await _save();
  }

  Future<void> _delete(String t, int id) async {
    _rows(t).removeWhere((r) => r['id'] == id);
    await _save();
  }

  List<Map<String, Object?>> _forVehicle(String t, int vid) =>
      _rows(t).where((r) => r['vehicle_id'] == vid).toList();

  int _byDateDesc(Map<String, Object?> a, Map<String, Object?> b) {
    final c = (b['date'] as int).compareTo(a['date'] as int);
    return c != 0 ? c : (b['id'] as int).compareTo(a['id'] as int);
  }

  // Vehicles
  Future<List<Vehicle>> vehicles() async =>
      ([..._rows('vehicles')]..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int)))
          .map(Vehicle.fromMap)
          .toList();
  Future<int> insertVehicle(Vehicle v) => _insert('vehicles', v.toMap());
  Future<void> updateVehicle(Vehicle v) => _update('vehicles', v.id, v.toMap());
  Future<void> deleteVehicle(int id) async {
    for (final t in ['service_items', 'service_logs', 'fuel_logs', 'odo_readings']) {
      _rows(t).removeWhere((r) => r['vehicle_id'] == id);
    }
    await _delete('vehicles', id);
  }

  // Service items
  Future<List<ServiceItem>> items(int vid) async =>
      (_forVehicle('service_items', vid)..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int)))
          .map(ServiceItem.fromMap)
          .toList();
  Future<int> insertItem(ServiceItem i) => _insert('service_items', i.toMap());
  Future<void> updateItem(ServiceItem i) => _update('service_items', i.id, i.toMap());
  Future<void> deleteItem(int id) => _delete('service_items', id);

  // Service logs
  Future<List<ServiceLog>> logs(int vid) async =>
      (_forVehicle('service_logs', vid)..sort(_byDateDesc)).map(ServiceLog.fromMap).toList();
  Future<int> insertLog(ServiceLog l) => _insert('service_logs', l.toMap());
  Future<void> deleteLog(int id) => _delete('service_logs', id);

  // Fuel logs
  Future<List<FuelLog>> fuel(int vid) async =>
      (_forVehicle('fuel_logs', vid)..sort(_byDateDesc)).map(FuelLog.fromMap).toList();
  Future<int> insertFuel(FuelLog f) => _insert('fuel_logs', f.toMap());
  Future<void> deleteFuel(int id) => _delete('fuel_logs', id);

  // ODO history (used to estimate how many km/day you ride)
  Future<List<OdoReading>> readings(int vid) async => (_forVehicle('odo_readings', vid)
        ..sort((a, b) {
          final c = (a['date'] as int).compareTo(b['date'] as int);
          return c != 0 ? c : (a['id'] as int).compareTo(b['id'] as int);
        }))
      .map(OdoReading.fromMap)
      .toList();
  Future<int> insertReading(OdoReading r) => _insert('odo_readings', r.toMap());

  // Settings
  Future<String?> getSetting(String key) async =>
      (_data['settings'] as Map<String, dynamic>)[key] as String?;

  Future<void> setSetting(String key, String value) async {
    (_data['settings'] as Map<String, dynamic>)[key] = value;
    await _save();
  }

  // Backup
  Future<Map<String, Object?>> dump() async => {
        'app': 'motolog',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        for (final t in _tables) t: _rows(t),
      };

  /// Replaces all vehicle data with the contents of a backup made by [dump].
  /// Throws [FormatException] if the data doesn't look like a MotoLog backup.
  Future<void> restore(Map<String, dynamic> backup) async {
    if (backup['app'] != 'motolog' || backup['vehicles'] is! List) {
      throw const FormatException('Not a MotoLog backup');
    }
    final next = <String, dynamic>{'settings': _data['settings']};
    for (final t in _tables) {
      next[t] = backup[t] ?? <dynamic>[];
    }
    final previous = _data;
    _data = next;
    try {
      _normalize();
      // Make sure the rows really parse before keeping them.
      for (final r in _rows('vehicles')) {
        Vehicle.fromMap(r);
      }
      for (final r in _rows('service_items')) {
        ServiceItem.fromMap(r);
      }
      for (final r in _rows('service_logs')) {
        ServiceLog.fromMap(r);
      }
      for (final r in _rows('fuel_logs')) {
        FuelLog.fromMap(r);
      }
      for (final r in _rows('odo_readings')) {
        OdoReading.fromMap(r);
      }
    } catch (e) {
      _data = previous;
      throw const FormatException('Backup file is damaged');
    }
    await _save();
  }
}
