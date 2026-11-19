import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'common.dart';

Future<T?> showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: builder(ctx),
      ),
    ),
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
}

Widget _title(BuildContext c, String text, [String? sub]) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: Theme.of(c).hintColor)),
          ],
        ],
      ),
    );

Future<DateTime?> pickDate(BuildContext context, DateTime initial) => showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

// ───────────────────────── Update ODO ─────────────────────────

class OdoSheet extends StatefulWidget {
  const OdoSheet({super.key});
  @override
  State<OdoSheet> createState() => _OdoSheetState();
}

class _OdoSheetState extends State<OdoSheet> {
  late final TextEditingController _c;
  String? _err;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: '${context.read<AppState>().active!.odo}');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final v = parseInt(_c.text);
    if (v == null) return setState(() => _err = 'Enter the number on your dashboard');
    if (v < state.active!.odo) {
      return setState(() => _err = 'Can\'t be lower than ${fmtKm(state.active!.odo)}');
    }
    await state.updateOdo(v);
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, 'Odometer updated');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Update odometer', 'Type what your dashboard shows right now.'),
        TextField(
          controller: _c,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          decoration: InputDecoration(suffixText: 'km', errorText: _err),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ───────────────────────── Log a service ─────────────────────────

class LogServiceSheet extends StatefulWidget {
  const LogServiceSheet({super.key, this.preselect});
  final ServiceItem? preselect;
  @override
  State<LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends State<LogServiceSheet> {
  final _selected = <int>{};
  late final TextEditingController _odo;
  final _extra = TextEditingController();
  final _cost = TextEditingController();
  final _shop = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String? _err;

  @override
  void initState() {
    super.initState();
    _odo = TextEditingController(text: '${context.read<AppState>().active!.odo}');
    final p = widget.preselect;
    if (p?.id != null) _selected.add(p!.id!);
  }

  @override
  void dispose() {
    for (final c in [_odo, _extra, _cost, _shop, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final odo = parseInt(_odo.text);
    if (_selected.isEmpty && _extra.text.trim().isEmpty) {
      return setState(() => _err = 'Pick at least one item or type what was done');
    }
    if (odo == null) return setState(() => _err = 'Enter the odometer reading');
    await state.logService(
      done: state.items.where((i) => _selected.contains(i.id)).toList(),
      extraTitle: _extra.text,
      odo: odo,
      date: _date,
      cost: parseDouble(_cost.text),
      shop: _shop.text.trim(),
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, 'Service logged');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Log a service', 'Tick everything that was done — reminders reset automatically.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final it in state.items.where((i) => i.enabled))
              FilterChip(
                avatar: Icon(iconFor(it.icon), size: 18),
                label: Text(it.name),
                selected: _selected.contains(it.id),
                onSelected: (v) => setState(() {
                  v ? _selected.add(it.id!) : _selected.remove(it.id);
                  _err = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _extra,
          decoration: const InputDecoration(labelText: 'Other work (optional)', hintText: 'e.g. replaced mirror'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _odo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ODO', suffixText: 'km'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () async {
                  final d = await pickDate(context, _date);
                  if (d != null) setState(() => _date = d);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(fmtDate(_date)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cost (optional)', prefixText: '₱ '),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _shop,
                decoration: const InputDecoration(labelText: 'Shop (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save service')),
      ],
    );
  }
}

// ───────────────────────── Fuel ─────────────────────────

class FuelSheet extends StatefulWidget {
  const FuelSheet({super.key});
  @override
  State<FuelSheet> createState() => _FuelSheetState();
}

class _FuelSheetState extends State<FuelSheet> {
  late final TextEditingController _odo;
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _trip = TextEditingController();
  DateTime _date = DateTime.now();
  bool _full = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _odo = TextEditingController(text: '${context.read<AppState>().active!.odo}');
  }

  @override
  void dispose() {
    for (final c in [_odo, _liters, _price, _trip]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Total paid = liters × price per liter, rounded to centavos.
  double? get _total {
    final l = parseDouble(_liters.text);
    final p = parseDouble(_price.text);
    if (l == null || p == null || l <= 0 || p <= 0) return null;
    return (l * p * 100).round() / 100;
  }

  Future<void> _save() async {
    final s = context.read<AppState>();
    final isFirst = s.fuel.isEmpty;
    final odo = parseInt(_odo.text);
    final l = parseDouble(_liters.text);
    final price = parseDouble(_price.text);
    final trip = parseDouble(_trip.text);

    if (l == null || l <= 0) return setState(() => _err = 'Enter the liters purchased');
    if (price == null || price <= 0) return setState(() => _err = 'Enter the price per liter');
    if (odo == null || odo < 0) return setState(() => _err = 'Enter your motorcycle\'s ODO reading');
    if (!isFirst) {
      if (trip == null || trip <= 0) {
        return setState(() => _err = 'Enter the TRIP B distance (must be more than 0)');
      }
      // TRIP B was reset at the previous refill, so it can't be longer than the ODO gap.
      final prev = s.fuelIntervals.last.log;
      if (!_date.isBefore(DateTime(prev.date.year, prev.date.month, prev.date.day)) &&
          trip > (odo - prev.odo) + 2) {
        return setState(() => _err =
            'TRIP B (${trip.toStringAsFixed(0)} km) is more than the ODO gain since your last fill-up (${fmtNum(odo - prev.odo)} km). Check both numbers.');
      }
    }

    await s.addFuel(
      odo: odo,
      date: _date,
      liters: l,
      totalCost: _total!,
      tripKm: isFirst ? null : trip,
      fullTank: _full,
    );
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, 'Fuel logged — now reset TRIP B to 0');
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = context.watch<AppState>().fuel.isEmpty;
    final hint = Theme.of(context).hintColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          context,
          'Add fuel',
          isFirst
              ? 'First fill-up sets your baseline. Reset TRIP B to 0 after fueling.'
              : 'Fuel economy = TRIP B distance ÷ liters.',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _liters,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Liters added', suffixText: 'L'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _price,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price per liter', prefixText: '₱ '),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _total == null ? 'Total paid: —' : 'Total paid: ₱${_total!.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _odo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ODO reading',
            suffixText: 'km',
            helperText: 'Your motorcycle\'s current total odometer reading.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _trip,
          enabled: !isFirst,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Distance traveled since last refill (TRIP B)',
            suffixText: 'km',
            helperText: isFirst
                ? 'Not needed for your first fill-up.'
                : 'Enter the distance shown on your motorcycle\'s TRIP B meter before resetting it.',
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tank filled to full'),
          subtitle: Text(
            'km/L is only counted when this and the previous fill-up were both full.',
            style: TextStyle(color: hint),
          ),
          value: _full,
          onChanged: (v) => setState(() => _full = v),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () async {
            final d = await pickDate(context, _date);
            if (d != null) setState(() => _date = d);
          },
          icon: const Icon(Icons.event_rounded),
          label: Text(fmtDate(_date)),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save fuel')),
      ],
    );
  }
}

// ───────────────────────── Reminder item editor ─────────────────────────

class ItemEditorSheet extends StatefulWidget {
  const ItemEditorSheet({super.key, this.item});
  final ServiceItem? item;
  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _km;
  late final TextEditingController _months;
  late final TextEditingController _lastOdo;
  late final TextEditingController _notes;
  late String _category;
  DateTime? _lastDate;
  String? _err;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _km = TextEditingController(text: i?.intervalKm?.toString() ?? '');
    _months = TextEditingController(text: i?.intervalMonths?.toString() ?? '');
    _lastOdo = TextEditingController(text: i?.lastOdo?.toString() ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
    _category = i?.category ?? 'Other';
    _lastDate = i?.lastDate;
  }

  @override
  void dispose() {
    for (final c in [_name, _km, _months, _lastOdo, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final km = parseInt(_km.text);
    final months = parseInt(_months.text);
    if (_name.text.trim().isEmpty) return setState(() => _err = 'Give it a name');
    if (km == null && months == null) {
      return setState(() => _err = 'Set an interval in km, months, or both');
    }
    final old = widget.item;
    await state.saveItem(ServiceItem(
      id: old?.id,
      vehicleId: state.active!.id!,
      name: _name.text.trim(),
      category: _category,
      icon: old?.icon ?? iconKeyForCategory(_category),
      intervalKm: km,
      intervalMonths: months,
      lastOdo: parseInt(_lastOdo.text),
      lastDate: _lastDate,
      notes: _notes.text.trim(),
      enabled: old?.enabled ?? true,
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this reminder?'),
        content: const Text('Past service logs are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().deleteItem(widget.item!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, editing ? 'Edit reminder' : 'New reminder'),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kCategories)
              ChoiceChip(
                label: Text(c),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _km,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Every (km)', hintText: 'optional'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Every (months)', hintText: 'optional'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lastOdo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Last done at (km)', hintText: 'ODO'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () async {
                  final d = await pickDate(context, _lastDate ?? DateTime.now());
                  if (d != null) setState(() => _lastDate = d);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(_lastDate == null ? 'Last date' : fmtDate(_lastDate!)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notes (oil grade, part numbers…)'),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save')),
        if (editing) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _delete,
            child: Text('Delete reminder', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Item detail ─────────────────────────

class ItemDetailSheet extends StatelessWidget {
  const ItemDetailSheet({super.key, required this.item});
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Re-read so the sheet reflects edits made while it is open.
    final it = state.items.firstWhere((i) => i.id == item.id, orElse: () => item);
    final info = state.dueFor(it);
    final c = stateColor(info.state);
    final t = Theme.of(context).textTheme;

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: Text(k, style: TextStyle(color: Theme.of(context).hintColor))),
              Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );

    final nextKm = (it.intervalKm != null && it.lastOdo != null) ? it.lastOdo! + it.intervalKm! : null;
    DateTime? nextDate;
    if (it.intervalMonths != null && it.lastDate != null) {
      final l = it.lastDate!;
      nextDate = DateTime(l.year, l.month + it.intervalMonths!, l.day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
              child: Icon(iconFor(it.icon), color: c, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(info.label, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        row('Interval', it.intervalText),
        row('Last done',
            [if (it.lastOdo != null) fmtKm(it.lastOdo!), if (it.lastDate != null) fmtDate(it.lastDate!)].join(' · ').ifEmpty('Not set')),
        if (nextKm != null) row('Next at', fmtKm(nextKm)),
        if (nextDate != null) row('Next by', fmtDate(nextDate)),
        if (info.estimatedDue != null && info.state != DueState.unknown)
          row('Estimated', '≈ ${fmtDate(info.estimatedDue!)} at ${state.kmPerDay.toStringAsFixed(0)} km/day'),
        if (it.notes.isNotEmpty) row('Notes', it.notes),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            showSheet(context, (_) => LogServiceSheet(preselect: it));
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Mark as done'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            showSheet(context, (_) => ItemEditorSheet(item: it));
          },
          child: const Text('Edit reminder'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          value: it.enabled,
          onChanged: (v) => state.saveItem(ServiceItem(
            id: it.id,
            vehicleId: it.vehicleId,
            name: it.name,
            category: it.category,
            icon: it.icon,
            intervalKm: it.intervalKm,
            intervalMonths: it.intervalMonths,
            lastOdo: it.lastOdo,
            lastDate: it.lastDate,
            notes: it.notes,
            enabled: v,
          )),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

// ───────────────────────── Quick actions (+ button) ─────────────────────────

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String title, String sub, Widget Function(BuildContext) sheet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SoftCard(
          onTap: () {
            Navigator.pop(context);
            showSheet(context, sheet);
          },
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(sub, style: TextStyle(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Quick add'),
        action(Icons.speed_rounded, 'Update odometer', 'Keep reminders accurate', (_) => const OdoSheet()),
        action(Icons.build_rounded, 'Log a service', 'Oil change, gear oil, repairs…', (_) => const LogServiceSheet()),
        action(Icons.local_gas_station_rounded, 'Add fuel', 'Track km/L and spending', (_) => const FuelSheet()),
        action(Icons.add_alarm_rounded, 'New reminder', 'Anything with a km or time interval', (_) => const ItemEditorSheet()),
      ],
    );
  }
}
