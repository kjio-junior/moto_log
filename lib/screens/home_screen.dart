import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.goTo});
  final void Function(int index) goTo;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = s.active!;
    final cs = Theme.of(context).colorScheme;
    final attention = s.ranked
        .where((e) => e.value.state == DueState.overdue || e.value.state == DueState.soon)
        .take(4)
        .toList();
    final unset = s.ranked.where((e) => e.value.state == DueState.unknown).length;
    final staleOdo = DateTime.now().difference(v.odoUpdatedAt).inDays >= 14;
    final recent = s.timeline.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickVehicle(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(v.name, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          // ODO hero
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kSeed, Color.lerp(kSeed, Colors.black, 0.3)!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [if (v.model.isNotEmpty) v.model, if (v.plate.isNotEmpty) v.plate].join(' · ').toUpperCase().ifBlank('ODOMETER'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(fmtNum(v.odo),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1.05)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('km',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Updated ${timeAgo(v.odoUpdatedAt)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showSheet(context, (_) => const OdoSheet()),
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('Update ODO'),
                ),
              ],
            ),
          ),

          if (staleOdo) ...[
            const SizedBox(height: 12),
            SoftCard(
              color: StatusBannerColors.of(context),
              onTap: () => showSheet(context, (_) => const OdoSheet()),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded),
                  SizedBox(width: 12),
                  Expanded(child: Text('Your ODO is a couple of weeks old — update it so due dates stay accurate.')),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  icon: Icons.route_rounded,
                  value: '${s.kmPerDay.toStringAsFixed(0)} km',
                  label: s.kmPerDayIsMeasured ? 'per day (measured)' : 'per day (estimate)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  icon: Icons.payments_rounded,
                  value: fmtMoney(s.thisMonthSpend),
                  label: 'spent this month',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  icon: Icons.local_gas_station_rounded,
                  value: s.kmPerLiter == null ? '—' : s.kmPerLiter!.toStringAsFixed(1),
                  label: 'km per liter',
                ),
              ),
            ],
          ),

          SectionHeader(
            'Needs attention',
            trailing: TextButton(onPressed: () => goTo(1), child: const Text('See all')),
          ),
          if (attention.isEmpty)
            SoftCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: StatusColors.ok, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      unset > 0
                          ? 'Nothing due. $unset reminders still need a "last done" value.'
                          : 'You\'re all caught up. Nothing is due soon.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final e in attention)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ItemTile(
                  item: e.key,
                  info: e.value,
                  onTap: () => showSheet(context, (_) => ItemDetailSheet(item: e.key)),
                ),
              ),

          if (recent.isNotEmpty) ...[
            SectionHeader(
              'Recent activity',
              trailing: TextButton(onPressed: () => goTo(2), child: const Text('History')),
            ),
            for (final e in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TimelineTile(
                  title: e.title,
                  subtitle: e.subtitle,
                  date: e.date,
                  isFuel: e.kind == 'fuel',
                  cost: e.cost,
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _pickVehicle(BuildContext context) {
    showSheet(context, (ctx) {
      final s = ctx.watch<AppState>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your vehicles',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final veh in s.vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                onTap: () {
                  s.selectVehicle(veh);
                  Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(veh.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(fmtKm(veh.odo)),
                    if (veh.id == s.active?.id) const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add another vehicle'),
          ),
        ],
      );
    });
  }
}

extension on String {
  String ifBlank(String other) => trim().isEmpty ? other : this;
}

class StatusBannerColors {
  static Color of(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF3A3020)
      : const Color(0xFFFFF3D6);
}
