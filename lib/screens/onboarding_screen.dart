import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../templates.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// Used for first launch and for "Add another vehicle".
class AddVehicleScreen extends StatelessWidget {
  const AddVehicleScreen({super.key});
  @override
  Widget build(BuildContext context) => const OnboardingScreen(addingAnother: true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.addingAnother = false});
  final bool addingAnother;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController(text: 'My Click 125i');
  final _model = TextEditingController(text: 'Honda Click 125i');
  final _plate = TextEditingController();
  final _odo = TextEditingController();
  final _perDay = TextEditingController(text: '15');
  bool _useTemplate = true;
  String? _err;
  bool _saving = false;

  late List<ServiceItem> _draft = click125iTemplate(0);
  late List<TextEditingController> _kmCtl = [for (final _ in _draft) TextEditingController()];
  late List<DateTime?> _dates = List<DateTime?>.filled(_draft.length, null);

  @override
  void dispose() {
    for (final c in [_name, _model, _plate, _odo, _perDay, ..._kmCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    final odo = parseInt(_odo.text);
    if (_name.text.trim().isEmpty) return setState(() => _err = 'Give your bike a name');
    if (odo == null) return setState(() => _err = 'Enter the number on your odometer');
    setState(() => _err = null);
    if (_useTemplate) {
      setState(() => _step = 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final odo = parseInt(_odo.text)!;
    final state = context.read<AppState>();
    final items = <ServiceItem>[];
    if (_useTemplate) {
      for (var i = 0; i < _draft.length; i++) {
        final last = parseInt(_kmCtl[i].text);
        if (last != null && last > odo) {
          return setState(() => _err = '"${_draft[i].name}": last-done ODO can\'t be above the current ODO');
        }
        items.add(ServiceItem(
          vehicleId: 0,
          name: _draft[i].name,
          category: _draft[i].category,
          icon: _draft[i].icon,
          intervalKm: _draft[i].intervalKm,
          intervalMonths: _draft[i].intervalMonths,
          lastOdo: last,
          lastDate: _dates[i],
          notes: _draft[i].notes,
        ));
      }
    }
    setState(() => _saving = true);
    await state.createVehicle(
      Vehicle(
        name: _name.text.trim(),
        model: _model.text.trim(),
        plate: _plate.text.trim(),
        odo: odo,
        avgKmPerDay: parseDouble(_perDay.text) ?? 15,
      ),
      items,
    );
    // Asks for notification permission; the app works fine if declined.
    if (state.remindersOn) await state.setReminders(true);
    if (!mounted) return;
    if (widget.addingAnother) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.addingAnother ? AppBar(title: const Text('Add vehicle')) : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == 0 ? _vehicleStep(context) : _itemsStep(context),
        ),
      ),
    );
  }

  Widget _vehicleStep(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('vehicle'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        if (!widget.addingAnother) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text('Welcome to MotoLog',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Let\'s set up your ride. It works offline, no account needed.',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16)),
          const SizedBox(height: 28),
        ],
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nickname')),
        const SizedBox(height: 12),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Make & model')),
        const SizedBox(height: 12),
        TextField(controller: _plate, decoration: const InputDecoration(labelText: 'Plate (optional)')),
        const SizedBox(height: 12),
        TextField(
          controller: _odo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current odometer', suffixText: 'km'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _perDay,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Roughly how far do you ride per day?',
            suffixText: 'km/day',
            helperText: 'Only a starting guess — the app learns your real pace from ODO updates.',
          ),
        ),
        const SizedBox(height: 20),
        Text('Starting reminders', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Click 125i schedule'), icon: Icon(Icons.menu_book_rounded)),
            ButtonSegment(value: false, label: Text('Start blank'), icon: Icon(Icons.edit_note_rounded)),
          ],
          selected: {_useTemplate},
          onSelectionChanged: (v) => setState(() => _useTemplate = v.first),
        ),
        if (_useTemplate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '15 reminders pre-filled from the maintenance schedule in your owner\'s manual. You can edit or delete any of them.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_err!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _next, child: Text(_useTemplate ? 'Next' : 'Finish')),
      ],
    );
  }

  Widget _itemsStep(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('items'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _step = 0),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text('When were these last done?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                child: Text(
                  'Enter the odometer reading from your last service for each item. '
                  'A rough guess is fine, and you can skip any you don\'t remember — set them later from the Reminders tab.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
              for (var i = 0; i < _draft.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(iconFor(_draft[i].icon), color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_draft[i].name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 34, top: 2, bottom: 10),
                          child: Text(_draft[i].intervalText.replaceFirst('every ', 'Every '),
                              style: TextStyle(color: Theme.of(context).hintColor)),
                        ),
                        Row(
                          children: [
                            if (_draft[i].intervalKm != null)
                              Expanded(
                                child: TextField(
                                  controller: _kmCtl[i],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Last done at',
                                    suffixText: 'km',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            if (_draft[i].intervalKm != null && _draft[i].intervalMonths != null)
                              const SizedBox(width: 10),
                            if (_draft[i].intervalMonths != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                  onPressed: () async {
                                    final d = await pickDate(context, _dates[i] ?? DateTime.now());
                                    if (d != null) setState(() => _dates[i] = d);
                                  },
                                  icon: const Icon(Icons.event_rounded, size: 18),
                                  label: Text(_dates[i] == null ? 'Date' : fmtDate(_dates[i]!)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (_err != null) Text(_err!, style: TextStyle(color: cs.error)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _saving ? null : _finish,
            child: Text(_saving ? 'Saving…' : 'Finish setup'),
          ),
        ),
      ],
    );
  }
}
