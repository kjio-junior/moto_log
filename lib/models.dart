import 'dart:math' as math;
import 'package:intl/intl.dart';

final _nf = NumberFormat('#,##0');
String fmtNum(num n) => _nf.format(n);
String fmtKm(num n) => '${_nf.format(n)} km';
String fmtMoney(num n) => '₱${_nf.format(n.round())}';
String fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 30) return '${diff.inDays} days ago';
  return fmtDate(d);
}

int? parseInt(String s) => int.tryParse(s.replaceAll(',', '').trim());
double? parseDouble(String s) => double.tryParse(s.replaceAll(',', '').trim());

DateTime _ms(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);
DateTime? _msN(Object? v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

// ───────────────────────── Vehicle ─────────────────────────

class Vehicle {
  Vehicle({
    this.id,
    required this.name,
    this.model = '',
    this.plate = '',
    required this.odo,
    DateTime? odoUpdatedAt,
    this.avgKmPerDay = 15,
  }) : odoUpdatedAt = odoUpdatedAt ?? DateTime.now();

  final int? id;
  final String name;
  final String model;
  final String plate;
  final int odo;
  final DateTime odoUpdatedAt;

  /// Fallback riding estimate, used until enough ODO history exists.
  final double avgKmPerDay;

  Vehicle copyWith({
    int? id,
    String? name,
    String? model,
    String? plate,
    int? odo,
    DateTime? odoUpdatedAt,
    double? avgKmPerDay,
  }) =>
      Vehicle(
        id: id ?? this.id,
        name: name ?? this.name,
        model: model ?? this.model,
        plate: plate ?? this.plate,
        odo: odo ?? this.odo,
        odoUpdatedAt: odoUpdatedAt ?? this.odoUpdatedAt,
        avgKmPerDay: avgKmPerDay ?? this.avgKmPerDay,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'model': model,
        'plate': plate,
        'odo': odo,
        'odo_updated_at': odoUpdatedAt.millisecondsSinceEpoch,
        'avg_km_day': avgKmPerDay,
      };

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as int?,
        name: m['name'] as String,
        model: (m['model'] as String?) ?? '',
        plate: (m['plate'] as String?) ?? '',
        odo: m['odo'] as int,
        odoUpdatedAt: _ms(m['odo_updated_at']),
        avgKmPerDay: (m['avg_km_day'] as num?)?.toDouble() ?? 15,
      );
}

// ───────────────────────── Service item (a reminder) ─────────────────────────

const kCategories = ['Engine', 'Drivetrain', 'Brakes', 'Chassis', 'Electrical', 'Other'];

String iconKeyForCategory(String c) => switch (c) {
      'Engine' => 'oil',
      'Drivetrain' => 'gear',
      'Brakes' => 'brake',
      'Chassis' => 'tyre',
      'Electrical' => 'battery',
      _ => 'wrench',
    };

class ServiceItem {
  ServiceItem({
    this.id,
    required this.vehicleId,
    required this.name,
    this.category = 'Other',
    this.icon = 'wrench',
    this.intervalKm,
    this.intervalMonths,
    this.lastOdo,
    this.lastDate,
    this.notes = '',
    this.enabled = true,
  });

  final int? id;
  final int vehicleId;
  final String name;
  final String category;
  final String icon;
  final int? intervalKm;
  final int? intervalMonths;
  final int? lastOdo;
  final DateTime? lastDate;
  final String notes;
  final bool enabled;

  ServiceItem copyWith({int? vehicleId, int? lastOdo, DateTime? lastDate, bool? enabled}) =>
      ServiceItem(
        id: id,
        vehicleId: vehicleId ?? this.vehicleId,
        name: name,
        category: category,
        icon: icon,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
        lastOdo: lastOdo ?? this.lastOdo,
        lastDate: lastDate ?? this.lastDate,
        notes: notes,
        enabled: enabled ?? this.enabled,
      );

  String get intervalText {
    final parts = <String>[];
    if (intervalKm != null) parts.add('every ${fmtKm(intervalKm!)}');
    if (intervalMonths != null) {
      final m = intervalMonths!;
      parts.add(m % 12 == 0 ? '${m ~/ 12} yr' : '$m mo');
    }
    return parts.isEmpty ? 'no interval' : parts.join(' / ');
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'name': name,
        'category': category,
        'icon': icon,
        'interval_km': intervalKm,
        'interval_months': intervalMonths,
        'last_odo': lastOdo,
        'last_date': lastDate?.millisecondsSinceEpoch,
        'notes': notes,
        'enabled': enabled ? 1 : 0,
      };

  factory ServiceItem.fromMap(Map<String, Object?> m) => ServiceItem(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        name: m['name'] as String,
        category: (m['category'] as String?) ?? 'Other',
        icon: (m['icon'] as String?) ?? 'wrench',
        intervalKm: m['interval_km'] as int?,
        intervalMonths: m['interval_months'] as int?,
        lastOdo: m['last_odo'] as int?,
        lastDate: _msN(m['last_date']),
        notes: (m['notes'] as String?) ?? '',
        enabled: (m['enabled'] as int? ?? 1) == 1,
      );
}

// ───────────────────────── Logs ─────────────────────────

class ServiceLog {
  ServiceLog({
    this.id,
    required this.vehicleId,
    this.itemIds = const [],
    required this.title,
    required this.odo,
    required this.date,
    this.cost,
    this.shop = '',
    this.notes = '',
  });

  final int? id;
  final int vehicleId;
  final List<int> itemIds;
  final String title;
  final int odo;
  final DateTime date;
  final double? cost;
  final String shop;
  final String notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'item_ids': itemIds.join(','),
        'title': title,
        'odo': odo,
        'date': date.millisecondsSinceEpoch,
        'cost': cost,
        'shop': shop,
        'notes': notes,
      };

  factory ServiceLog.fromMap(Map<String, Object?> m) => ServiceLog(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        itemIds: ((m['item_ids'] as String?) ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .map(int.parse)
            .toList(),
        title: m['title'] as String,
        odo: m['odo'] as int,
        date: _ms(m['date']),
        cost: (m['cost'] as num?)?.toDouble(),
        shop: (m['shop'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
      );
}

class FuelLog {
  FuelLog({
    this.id,
    required this.vehicleId,
    required this.odo,
    required this.date,
    required this.liters,
    required this.totalCost,
    this.tripKm,
    this.fullTank = true,
  });

  final int? id;
  final int vehicleId;

  /// Motorcycle's total odometer at the time of this refill. Never used for fuel economy.
  final int odo;
  final DateTime date;
  final double liters;
  final double totalCost;

  /// TRIP B distance (km) shown on the bike just before this refill, i.e. the distance
  /// since the previous refill. Null for the baseline (first) entry and for records
  /// saved before this field existed.
  final double? tripKm;

  /// Whether the tank was filled to full. Only full-to-full pairs give a valid km/L.
  final bool fullTank;

  double get pricePerLiter => liters == 0 ? 0 : totalCost / liters;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'odo': odo,
        'date': date.millisecondsSinceEpoch,
        'liters': liters,
        'total_cost': totalCost,
        'trip_km': tripKm,
        'full_tank': fullTank ? 1 : 0,
      };

  // Older records have no trip_km / full_tank: they load as-is (tripKm null, fullTank true).
  factory FuelLog.fromMap(Map<String, Object?> m) => FuelLog(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        odo: m['odo'] as int,
        date: _ms(m['date']),
        liters: (m['liters'] as num).toDouble(),
        totalCost: (m['total_cost'] as num).toDouble(),
        tripKm: (m['trip_km'] as num?)?.toDouble(),
        fullTank: (m['full_tank'] as num? ?? 1) != 0,
      );
}

class OdoReading {
  OdoReading({this.id, required this.vehicleId, required this.odo, required this.date});
  final int? id;
  final int vehicleId;
  final int odo;
  final DateTime date;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'odo': odo,
        'date': date.millisecondsSinceEpoch,
      };

  factory OdoReading.fromMap(Map<String, Object?> m) => OdoReading(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        odo: m['odo'] as int,
        date: _ms(m['date']),
      );
}

// ───────────────────────── Due-date engine ─────────────────────────

enum DueState { unknown, ok, soon, overdue }

class DueInfo {
  const DueInfo({
    required this.state,
    required this.label,
    this.kmLeft,
    this.daysLeft,
    this.progress = 0,
    this.urgentDays = double.infinity,
    this.estimatedDue,
  });

  final DueState state;
  final String label;
  final int? kmLeft;
  final int? daysLeft;

  /// 0 → just serviced, 1 → due now, >1 → overdue.
  final double progress;

  /// Days until the *earlier* of the km / time limits (km converted via riding pace).
  final double urgentDays;
  final DateTime? estimatedDue;
}

/// Works out how close a service item is to being due.
/// Handles km-based, time-based, or both (whichever comes first wins).
DueInfo computeDue(ServiceItem it, int odo, double kmPerDay, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final perDay = math.max(kmPerDay, 1.0);
  int? kmLeft;
  int? daysLeft;
  double progress = 0;

  if (it.intervalKm != null && it.lastOdo != null) {
    kmLeft = it.lastOdo! + it.intervalKm! - odo;
    progress = math.max(progress, (it.intervalKm! - kmLeft) / it.intervalKm!);
  }
  if (it.intervalMonths != null && it.lastDate != null) {
    final l = it.lastDate!;
    final start = DateTime(l.year, l.month, l.day);
    final due = DateTime(l.year, l.month + it.intervalMonths!, l.day);
    daysLeft = due.difference(today).inDays;
    final total = due.difference(start).inDays;
    if (total > 0) progress = math.max(progress, (total - daysLeft) / total);
  }

  if (kmLeft == null && daysLeft == null) {
    return const DueInfo(state: DueState.unknown, label: 'Set last service');
  }

  final kmDays = kmLeft == null ? double.infinity : kmLeft / perDay;
  final timeDays = daysLeft == null ? double.infinity : daysLeft.toDouble();
  final urgent = math.min(kmDays, timeDays);

  final overdue = (kmLeft != null && kmLeft < 0) || (daysLeft != null && daysLeft < 0);
  final soonKm = math.max(300, ((it.intervalKm ?? 0) * 0.1).round());
  final soon = (kmLeft != null && kmLeft <= soonKm) || (daysLeft != null && daysLeft <= 30);
  final state = overdue
      ? DueState.overdue
      : soon
          ? DueState.soon
          : DueState.ok;

  final useKm = kmLeft != null && kmDays <= timeDays;
  String label;
  if (useKm) {
    final k = kmLeft!;
    label = k >= 0 ? '${fmtKm(k)} left' : '${fmtKm(-k)} overdue';
  } else {
    final d = daysLeft!;
    label = d < 0
        ? '${-d} days overdue'
        : d == 0
            ? 'Due today'
            : d >= 60
                ? 'in ${(d / 30).round()} months'
                : 'in $d days';
  }

  return DueInfo(
    state: state,
    label: label,
    kmLeft: kmLeft,
    daysLeft: daysLeft,
    progress: progress,
    urgentDays: urgent,
    estimatedDue: now.add(Duration(days: urgent.round())),
  );
}
