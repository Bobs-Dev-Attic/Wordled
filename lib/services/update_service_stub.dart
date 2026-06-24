import '../version.dart';
import 'logger.dart';
import 'maintenance_result.dart';
import 'storage.dart';

/// Non-web implementation of [UpdateService]. Native builds have no service
/// worker or browser cache, so the update/cache actions are no-ops; the nuclear
/// reset still wipes all saved data. Kept API-compatible with the web version.
class UpdateService {
  UpdateService(this._storage);

  final Storage _storage;

  Future<void> trackVersion() async {
    final last = _storage.loadLastVersion();
    if (last == null) {
      log.i('update', 'First launch on version $kAppVersionFull');
    } else if (last != kAppVersionFull) {
      log.i('update', 'App updated: $last -> $kAppVersionFull');
    } else {
      log.d('update',
          'Running version $kAppVersionFull (no change since last run)');
    }
    await _storage.saveLastVersion(kAppVersionFull);
  }

  /// On native platforms updates arrive via a new installed build.
  Future<bool> checkForUpdates() async {
    log.i('update', 'Native build — install a new APK to update.');
    return false;
  }

  Future<MaintenanceResult> applyUpdate() async =>
      MaintenanceResult(false, 'Install a new build to update.');

  Future<MaintenanceResult> clearCacheAndReload() async =>
      MaintenanceResult(true, 'Nothing to clear on this platform.');

  Future<MaintenanceResult> nuclearReset() async {
    log.w('update', '*** NUCLEAR RESET (native) ***');
    await _storage.wipeAll();
    return MaintenanceResult(true, 'All saved data wiped. Restart the app.');
  }
}
