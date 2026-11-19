import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

Color stateColor(DueState s) => switch (s) {
      DueState.ok => StatusColors.ok,
      DueState.soon => StatusColors.soon,
      DueState.overdue => StatusColors.overdue,
      DueState.unknown => StatusColors.unknown,
    };

IconData iconFor(String key) => switch (key) {
      'oil' => Icons.opacity_rounded,
      'gear' => Icons.settings_rounded,
      'plug' => Icons.bolt_rounded,
      'air' => Icons.air_rounded,
      'belt' => Icons.autorenew_rounded,
      'valve' => Icons.tune_rounded,
      'filter' => Icons.filter_alt_rounded,
      'brake' => Icons.stop_circle_rounded,
      'coolant' => Icons.thermostat_rounded,
      'tyre' => Icons.tire_repair_rounded,
      'battery' => Icons.battery_charging_full_rounded,
      _ => Icons.handyman_rounded,
    };

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color ?? (dark ? const Color(0xFF211F1C) : Colors.white),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, required this.info, this.onTap});
  final ServiceItem item;
  final DueInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = stateColor(info.state);
    final t = Theme.of(context).textTheme;
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(iconFor(item.icon), color: c),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(info.label,
                    style: t.bodySmall?.copyWith(color: c, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: info.state == DueState.unknown
                        ? 0
                        : info.progress.clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    color: c,
                    backgroundColor: c.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message});
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Theme.of(context).hintColor),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ],
        ),
      );
}

class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.title, required this.subtitle, required this.date, required this.isFuel, this.cost});
  final String title;
  final String subtitle;
  final DateTime date;
  final bool isFuel;
  final double? cost;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = isFuel ? cs.tertiary : cs.primary;
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isFuel ? Icons.local_gas_station_rounded : Icons.build_rounded, color: c),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${fmtDate(date)} · $subtitle',
                    style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          if (cost != null && cost! > 0)
            Text(fmtMoney(cost!), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
