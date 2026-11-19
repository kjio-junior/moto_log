import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final months = s.monthlySpend();
    final cs = Theme.of(context).colorScheme;
    final maxTotal = months.fold<double>(1, (m, e) => e.total > m ? e.total : m);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          Row(
            children: [
              Expanded(child: StatBox(icon: Icons.build_rounded, value: fmtMoney(s.totalServiceCost), label: 'on maintenance')),
              const SizedBox(width: 10),
              Expanded(child: StatBox(icon: Icons.local_gas_station_rounded, value: fmtMoney(s.totalFuelCost), label: 'on fuel')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  icon: Icons.speed_rounded,
                  value: s.kmPerLiter == null ? '—' : '${s.kmPerLiter!.toStringAsFixed(1)} km/L',
                  label: s.fuelEconomySamples == 0
                      ? 'average economy'
                      : 'avg economy · ${s.fuelEconomySamples} fill-up${s.fuelEconomySamples == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  icon: Icons.payments_rounded,
                  value: s.fuelCostPerKm == null ? '—' : '₱${s.fuelCostPerKm!.toStringAsFixed(2)}',
                  label: 'fuel cost per km',
                ),
              ),
            ],
          ),
          const SectionHeader('Last 6 months'),
          SoftCard(
            child: Column(
              children: [
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final m in months)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                m.total == 0 ? '' : NumberFormat.compact().format(m.total),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: 100 * m.fuel / maxTotal,
                                decoration: BoxDecoration(
                                  color: cs.tertiary,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ),
                              Container(width: 22, height: 100 * m.service / maxTotal, color: cs.primary),
                              const SizedBox(height: 6),
                              Text(DateFormat('MMM').format(m.month), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(cs.primary, 'Maintenance'),
                    const SizedBox(width: 18),
                    _legend(cs.tertiary, 'Fuel'),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Riding'),
          SoftCard(
            child: Column(
              children: [
                _line('Distance tracked', fmtKm(s.kmTracked)),
                _line('Riding pace', '${s.kmPerDay.toStringAsFixed(0)} km/day${s.kmPerDayIsMeasured ? '' : ' (estimate)'}'),
                _line('Fill-ups logged', '${s.fuel.length}'),
                _line('Fill-ups with valid km/L', '${s.fuelEconomySamples}'),
                _line('Services logged', '${s.logs.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))],
        ),
      );
}
