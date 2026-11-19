import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = s.active;
    if (v == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const SectionHeader('Vehicle'),
          SoftCard(
            onTap: () => showSheet(context, (_) => _VehicleEditSheet(vehicle: v)),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text([v.model, v.plate].where((e) => e.isNotEmpty).join(' · '),
                          style: TextStyle(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                const Icon(Icons.edit_rounded, size: 20),
              ],
            ),
          ),
          const SectionHeader('Appearance'),
          SoftCard(
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => s.setThemeMode(v.first),
              ),
            ),
          ),
          const SectionHeader('Notifications'),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              title: const Text('Maintenance reminders'),
              subtitle: const Text(
                  'A heads-up about a week before something is due, plus a weekly nudge to update your ODO.'),
              value: s.remindersOn,
              onChanged: s.setReminders,
            ),
          ),
          const SectionHeader('Data'),
          SoftCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: Text(s.sync.label),
                  subtitle: const Text('Everything is saved locally first, so no signal is never a problem.'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ios_share_rounded),
                  title: const Text('Export backup'),
                  subtitle: const Text('Save a copy to Drive, WhatsApp, email…'),
                  onTap: () => s.exportBackup(),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_open_rounded),
                  title: const Text('Import backup'),
                  subtitle: const Text('Restore from a MotoLog backup file'),
                  onTap: () => _import(context, s),
                ),
              ],
            ),
          ),
          if (s.vehicles.length > 1) ...[
            const SectionHeader('Danger zone'),
          ] else
            const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete ${v.name}?'),
                  content: const Text('This removes its reminders, service history and fuel logs from this device.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              Navigator.pop(context);
              await s.deleteVehicle(v);
            },
            icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            label: Text('Delete this vehicle', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

Future<void> _import(BuildContext context, AppState s) async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return;
  final path = files.first.path;
  if (path == null) return;
  final bytes = await File(path).readAsBytes();
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace current data?'),
      content: const Text('Everything in the app now will be replaced by the backup.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await s.importBackup(utf8.decode(bytes));
    if (!context.mounted) return;
    if (s.active == null) {
      Navigator.pop(context);
    } else {
      toast(context, 'Backup restored');
    }
  } catch (_) {
    if (context.mounted) toast(context, 'That file isn\'t a valid MotoLog backup');
  }
}

class _VehicleEditSheet extends StatefulWidget {
  const _VehicleEditSheet({required this.vehicle});
  final Vehicle vehicle;
  @override
  State<_VehicleEditSheet> createState() => _VehicleEditSheetState();
}

class _VehicleEditSheetState extends State<_VehicleEditSheet> {
  late final _name = TextEditingController(text: widget.vehicle.name);
  late final _model = TextEditingController(text: widget.vehicle.model);
  late final _plate = TextEditingController(text: widget.vehicle.plate);
  late final _perDay = TextEditingController(text: widget.vehicle.avgKmPerDay.toStringAsFixed(0));

  @override
  void dispose() {
    for (final c in [_name, _model, _plate, _perDay]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edit vehicle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nickname')),
        const SizedBox(height: 12),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Make & model')),
        const SizedBox(height: 12),
        TextField(controller: _plate, decoration: const InputDecoration(labelText: 'Plate')),
        const SizedBox(height: 12),
        TextField(
          controller: _perDay,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Fallback riding pace', suffixText: 'km/day'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            if (_name.text.trim().isEmpty) return;
            await context.read<AppState>().updateVehicle(widget.vehicle.copyWith(
                  name: _name.text.trim(),
                  model: _model.text.trim(),
                  plate: _plate.text.trim(),
                  avgKmPerDay: parseDouble(_perDay.text) ?? widget.vehicle.avgKmPerDay,
                ));
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
