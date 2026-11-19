import 'package:flutter/material.dart';

import '../widgets/sheets.dart';
import 'home_screen.dart';
import 'logs_screen.dart';
import 'maintenance_screen.dart';
import 'stats_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(goTo: (i) => setState(() => _index = i)),
      const MaintenanceScreen(),
      const LogsScreen(),
      const StatsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSheet(context, (_) => const QuickActionsSheet()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Reminders'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Stats'),
        ],
      ),
    );
  }
}
