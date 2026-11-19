# MotoLog — offline-first motorcycle maintenance tracker (Flutter)

Built around a Honda Click 125i (PH) but works for any bike: reminders are fully editable.

## Set up

```bash
flutter create --org com.yourname --project-name moto_log moto_log
cd moto_log
# copy this project's lib/, test/ and pubspec.yaml over the generated ones
# (delete the generated test/widget_test.dart)
flutter pub get
flutter test          # runs the due-date engine tests
flutter run
```

### Android (needed for reminders)

`android/app/build.gradle.kts`

```kotlin
android {
    compileOptions { isCoreLibraryDesugaringEnabled = true }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

`android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

…and inside `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

## How reminders work

Phones can't watch your odometer, so the app projects due dates instead:

1. Each reminder has an interval in km, months, or both (whichever comes first wins).
2. You enter the ODO it was last done at (setup screen, or later from the Reminders tab).
3. Every ODO update teaches the app your real riding pace (km/day, last 90 days).
4. After each update or service log, it re-plans local notifications: a heads-up ~7 days before the projected due date, weekly nudges once overdue, and a Sunday "update your ODO" check-in.

## Structure

```
lib/
  main.dart                 app entry, onboarding vs. main shell
  models.dart               data classes + computeDue() (the due-date engine)
  templates.dart            Click 125i schedule from the owner's manual (pp. 58-59, 119)
  db.dart                   local JSON-file storage + backup restore
  app_state.dart            state, stats, notification planning, backup export
  notification_service.dart all flutter_local_notifications code (one file to fix on upgrade)
  sync_service.dart         plug-in point for cloud sync (currently local-only)
  screens/                  home, reminders, history, stats, settings, onboarding
  widgets/                  shared UI + bottom-sheet forms
```

## Not done yet

- Cloud sync / multi-device (interface exists, no backend wired)
- iOS foreground-notification setup (see flutter_local_notifications docs)
