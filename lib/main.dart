import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'db.dart';
import 'notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'sync_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDb.open();
  final notifications = NotificationService();
  await notifications.init();

  final state = AppState(db, notifications, LocalOnlySync());
  await state.load();

  runApp(ChangeNotifierProvider.value(value: state, child: const MotoLogApp()));
}

class MotoLogApp extends StatelessWidget {
  const MotoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoLog',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: context.select<AppState, ThemeMode>((s) => s.themeMode),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final hasVehicle = context.select<AppState, bool>((s) => s.active != null);
    return hasVehicle ? const Shell() : const OnboardingScreen();
  }
}
