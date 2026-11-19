/// Local-first design: local storage is always the source of truth, so the app works
/// with no signal. To add online backup/multi-device sync later, implement this
/// interface (Firebase, Supabase, your own API…) and pass it to AppState in main.dart.
abstract class SyncService {
  String get label;
  bool get isConnected;

  /// Called after every local write. Implementations should queue and push
  /// changes when a connection is available, and never block the UI.
  Future<void> syncNow();
}

class LocalOnlySync implements SyncService {
  @override
  String get label => 'Stored on this device (works fully offline)';

  @override
  bool get isConnected => false;

  @override
  Future<void> syncNow() async {}
}
