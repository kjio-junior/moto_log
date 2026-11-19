import 'package:flutter_test/flutter_test.dart';
import 'package:moto_log/models.dart';

ServiceItem oil({int? lastOdo, DateTime? lastDate}) => ServiceItem(
      vehicleId: 1,
      name: 'Engine oil',
      intervalKm: 6000,
      intervalMonths: 12,
      lastOdo: lastOdo,
      lastDate: lastDate,
    );

void main() {
  final now = DateTime(2026, 11, 19);

  test('unknown when nothing has been recorded', () {
    expect(computeDue(oil(), 12000, 15, now).state, DueState.unknown);
  });

  test('ok when plenty of km are left', () {
    final d = computeDue(oil(lastOdo: 10000), 12000, 15, now);
    expect(d.state, DueState.ok);
    expect(d.kmLeft, 4000);
  });

  test('soon when within 10% of the interval', () {
    final d = computeDue(oil(lastOdo: 10000), 15500, 15, now);
    expect(d.state, DueState.soon);
    expect(d.kmLeft, 500);
  });

  test('overdue past the interval', () {
    final d = computeDue(oil(lastOdo: 10000), 16100, 15, now);
    expect(d.state, DueState.overdue);
    expect(d.label, '100 km overdue');
  });

  test('time limit wins when it comes first', () {
    final d = computeDue(oil(lastOdo: 15900, lastDate: DateTime(2025, 10, 1)), 16000, 15, now);
    expect(d.state, DueState.overdue);
    expect(d.daysLeft! < 0, true);
  });
}
