import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ranked = s.ranked;
    final disabled = s.items.where((i) => !i.enabled).toList();

    List<Widget> section(String title, DueState state) {
      final list = ranked.where((e) => e.value.state == state).toList();
      if (list.isEmpty) return [];
      return [
        SectionHeader(title),
        for (final e in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ItemTile(
              item: e.key,
              info: e.value,
              onTap: () => showSheet(context, (_) => ItemDetailSheet(item: e.key)),
            ),
          ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            tooltip: 'New reminder',
            icon: const Icon(Icons.add_alarm_rounded),
            onPressed: () => showSheet(context, (_) => const ItemEditorSheet()),
          ),
        ],
      ),
      body: s.items.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No reminders yet',
                message: 'Tap the alarm icon to add one — oil change, gear oil, anything.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Text(
                    'Due dates are projected from your ODO and riding pace '
                    '(~${s.kmPerDay.toStringAsFixed(0)} km/day).',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
                ...section('Overdue', DueState.overdue),
                ...section('Due soon', DueState.soon),
                ...section('On track', DueState.ok),
                ...section('Set "last done" to start tracking', DueState.unknown),
                if (disabled.isNotEmpty) ...[
                  const SectionHeader('Paused'),
                  for (final it in disabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ItemTile(
                        item: it,
                        info: const DueInfo(state: DueState.unknown, label: 'Reminders off'),
                        onTap: () => showSheet(context, (_) => ItemDetailSheet(item: it)),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
