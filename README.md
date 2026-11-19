# MotoLog

A simple, offline-first motorcycle maintenance and fuel tracker built with Flutter.
Keep your service reminders, fuel fill-ups and mileage in one place, with no account and no signal needed.

## Features

- **Maintenance reminders**: track items like engine oil, brake pads and chain, by distance, by time, or both. Progress is based on your ODO, and the app tells you what's due soon or overdue.
- **Smart due dates**: estimates when each item will be due from your riding pace, and sends a heads-up about a week before.
- **Fuel tracking**: log liters and price per liter (the total is calculated for you), with ODO and TRIP B distance for accurate km/L.
- **Stats**: average fuel economy, fuel cost per km, monthly spending for the last 6 months, and distance tracked.
- **Multiple vehicles**: switch between bikes, each with its own history.
- **Backup and restore**: export everything as a file and import it again later.
- **Light and dark mode**: follow the system or pick one in Settings.
- **Offline first**: data is saved locally on your device first.

## How fuel economy works

MotoLog keeps **ODO** and **TRIP B** separate.

| | Used for |
| --- | --- |
| **ODO** (total mileage, never reset) | Maintenance schedules and distance tracked |
| **TRIP B** (distance since last refill) | Fuel economy |

Routine: refuel, log it, reset TRIP B to 0. At the next refill, enter the TRIP B distance before resetting it.

```
km/L = TRIP B distance / liters added
```

- The first fill-up is a baseline and has no km/L.
- A km/L is only counted when this fill-up and the previous one were both filled to full.
- ODO differences are never used for fuel economy.

Example: 85 km on TRIP B and 3.2 L added gives 85 / 3.2 = 26.56 km/L.

## Getting started

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) and the Android SDK (Android Studio).

```bash
git clone <your-repo-url>
cd moto_log
flutter pub get
flutter run
```

Pick a device or emulator when asked, or use `flutter run -d <device-id>`.

To build an APK:

```bash
flutter build apk --release
```

## Project structure

```
lib/
  main.dart                  App entry and theme
  app_state.dart             State, fuel and stats logic
  models.dart                Vehicle, service item, log and fuel models, due-date engine
  db.dart                    Local JSON storage
  notification_service.dart  Local notifications (all plugin code lives here)
  theme.dart                 Light and dark themes
  screens/                   Home, maintenance, logs, stats, settings, onboarding
  widgets/                   Shared widgets and bottom sheets
android/                     Android config, app icon, splash and notification icons
```

## Data and privacy

Everything is stored in a single JSON file in the app's private storage on your device.
Nothing is uploaded anywhere. Use **Settings > Export backup** to save a copy.

## Built with

- [Flutter](https://flutter.dev)
- [provider](https://pub.dev/packages/provider) for state
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) for reminders
- [file_picker](https://pub.dev/packages/file_picker) and [share_plus](https://pub.dev/packages/share_plus) for backups
