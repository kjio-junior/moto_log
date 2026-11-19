import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = 'all'; // all | service | fuel

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final entries = s.timeline.where((e) => _filter == 'all' || e.kind == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (final f in const [('all', 'All'), ('service', 'Service'), ('fuel', 'Fuel')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: Icons.history_rounded,
                      title: 'Nothing logged yet',
                      message: 'Use the Add button to log a service or a fill-up.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return Dismissible(
                        key: ValueKey('${e.kind}-${e.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async =>
                            await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete this entry?'),
                                content: const Text(
                                    'Reminders keep their current "last done" values — edit them from the Reminders tab if needed.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            ) ??
                            false,
                        onDismissed: (_) => s.deleteTimelineEntry(e),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: StatusColorsLite.red,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        child: TimelineTile(
                          title: e.title,
                          subtitle: e.subtitle,
                          date: e.date,
                          isFuel: e.kind == 'fuel',
                          cost: e.cost,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StatusColorsLite {
  static const red = Color(0xFFD64545);
}
