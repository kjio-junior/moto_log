import 'models.dart';

/// Default reminders for the Honda Click 125i (PH, ACB125CBT) —
/// intervals taken from the Maintenance Schedule in the owner's manual (pp. 58–59)
/// and specs from p. 119. Everything stays editable in the app.
List<ServiceItem> click125iTemplate(int vehicleId) => [
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Engine oil',
        category: 'Engine',
        icon: 'oil',
        intervalKm: 6000,
        intervalMonths: 12,
        notes: 'Honda 4-stroke oil, SAE 10W-30, JASO MB (API SG or higher). '
            '0.8 L when changing oil; 0.9 L after full disassembly. '
            'Manual: first change at ~1,000 km, then every 6,000 km or yearly.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Gear oil (final drive)',
        category: 'Drivetrain',
        icon: 'gear',
        intervalMonths: 24,
        notes: 'Manual lists replacement every 2 years (no km interval). '
            'Capacity 0.12 L after draining. Add a km interval if your mechanic recommends one.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Spark plug',
        category: 'Engine',
        icon: 'plug',
        intervalKm: 12000,
        notes: 'NGK CPR9EA-9 or Denso U27EPR9, gap 0.8–0.9 mm. '
            'Manual: inspect every 6,000 km, replace every 12,000 km.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Air cleaner element',
        category: 'Engine',
        icon: 'air',
        intervalKm: 18000,
        notes: 'Replace more often if you ride in dusty or wet conditions.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Drive belt',
        category: 'Drivetrain',
        icon: 'belt',
        intervalKm: 24000,
        notes: 'Manual: inspect at 12,000 km, replace at 24,000 km.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Valve clearance check',
        category: 'Engine',
        icon: 'valve',
        intervalKm: 6000,
        notes: 'Inspection only; adjust if out of spec.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Oil strainer screen clean',
        category: 'Engine',
        icon: 'filter',
        intervalKm: 12000,
        notes: 'Needs special tools; usually done during an oil change at the shop.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Brake fluid',
        category: 'Brakes',
        icon: 'brake',
        intervalMonths: 24,
        notes: 'Honda DOT 3 or DOT 4. Replace every 2 years; check level and pads every 6,000 km.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Brake pads & shoes check',
        category: 'Brakes',
        icon: 'brake',
        intervalKm: 6000,
        notes: 'Front pads and rear shoes wear inspection.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Radiator coolant',
        category: 'Engine',
        icon: 'coolant',
        intervalMonths: 36,
        notes: 'Honda PRE-MIX COOLANT, 0.51 L system capacity. Replace every 3 years.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Clutch shoes check',
        category: 'Drivetrain',
        icon: 'wrench',
        intervalKm: 12000,
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Tyres & pressure',
        category: 'Chassis',
        icon: 'tyre',
        intervalKm: 6000,
        notes: 'Pressure: 200 kPa (29 psi) front, 225 kPa (33 psi) rear. '
            'Tyres: front 80/90-14, rear 90/90-14.',
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Nuts, bolts & fasteners',
        category: 'Chassis',
        icon: 'wrench',
        intervalKm: 12000,
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Steering head bearings',
        category: 'Chassis',
        icon: 'wrench',
        intervalKm: 12000,
      ),
      ServiceItem(
        vehicleId: vehicleId,
        name: 'Battery check',
        category: 'Electrical',
        icon: 'battery',
        intervalKm: 6000,
        notes: 'GTZ6V (12 V 5 Ah).',
      ),
    ];
