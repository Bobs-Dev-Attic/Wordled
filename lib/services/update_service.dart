import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../version.dart';
import 'logger.dart';
import 'storage.dart';

/// Result of a maintenance action, for surfacing in the UI.
class MaintenanceResult {
  MaintenanceResult(this.success, this.message);
  final bool success;
  final String message;
}

/// Manages app version tracking, service-worker updates, and cache control for
/// the web build. All operations log verbosely so the in-app log viewer shows
/// exactly what happened.
class UpdateService {
  UpdateService(this._storage);

  final Storage _storage;

  /// Compares the persisted version with the running one and logs the result.
  Future<void> trackVersion() async {
    final last = _storage.loadLastVersion();
    if (last == null) {
      log.i('update', 'First launch on version $kAppVersionFull');
    } else if (last != kAppVersionFull) {
      log.i('update', 'App updated: $last -> $kAppVersionFull');
    } else {
      log.d('update', 'Running version $kAppVersionFull (no change since last run)');
    }
    await _storage.saveLastVersion(kAppVersionFull);
  }

  bool get _serviceWorkerSupported {
    try {
      return (web.window.navigator as JSObject).has('serviceWorker');
    } catch (_) {
      return false;
    }
  }

  // ---- Caches ---------------------------------------------------------------

  Future<List<String>> cacheNames() async {
    try {
      final keys = await web.window.caches.keys().toDart;
      return keys.toDart.map((e) => (e).toDart).toList();
    } catch (e) {
      log.w('update', 'Unable to read cache names: $e');
      return [];
    }
  }

  /// Deletes every Cache Storage entry. Returns the number removed.
  Future<int> clearCaches() async {
    final names = await cacheNames();
    log.i('update', 'Clearing ${names.length} cache(s): ${names.join(', ')}');
    var removed = 0;
    for (final name in names) {
      try {
        final ok = await web.window.caches.delete(name).toDart;
        if (ok.toDart) removed++;
        log.d('update', 'Deleted cache "$name": ${ok.toDart}');
      } catch (e) {
        log.e('update', 'Failed to delete cache "$name": $e');
      }
    }
    log.i('update', 'Removed $removed cache(s)');
    return removed;
  }

  // ---- Service worker -------------------------------------------------------

  /// Asks the browser to check for a newer service worker. Returns true if an
  /// update is installing or waiting to activate.
  Future<bool> checkForUpdates() async {
    if (!_serviceWorkerSupported) {
      log.w('update', 'Service workers are not supported in this browser');
      return false;
    }
    try {
      log.i('update', 'Checking for updates...');
      final regs =
          await web.window.navigator.serviceWorker.getRegistrations().toDart;
      final list = regs.toDart;
      if (list.isEmpty) {
        log.w('update', 'No service-worker registration found');
        return false;
      }
      var hasUpdate = false;
      for (final reg in list) {
        await reg.update().toDart;
        final waiting = reg.waiting != null;
        final installing = reg.installing != null;
        log.i('update',
            'Registration ${reg.scope}: waiting=$waiting installing=$installing');
        hasUpdate = hasUpdate || waiting || installing;
      }
      log.i('update', hasUpdate
          ? 'Update available — reload to apply'
          : 'Already up to date');
      return hasUpdate;
    } catch (e) {
      log.e('update', 'Update check failed: $e');
      return false;
    }
  }

  Future<void> unregisterServiceWorkers() async {
    if (!_serviceWorkerSupported) return;
    try {
      final regs =
          await web.window.navigator.serviceWorker.getRegistrations().toDart;
      for (final reg in regs.toDart) {
        final ok = await reg.unregister().toDart;
        log.i('update', 'Unregistered service worker (${reg.scope}): ${ok.toDart}');
      }
    } catch (e) {
      log.w('update', 'Service-worker unregister failed: $e');
    }
  }

  void clearWebStorage() {
    try {
      web.window.localStorage.clear();
      web.window.sessionStorage.clear();
      log.i('update', 'Cleared local and session storage');
    } catch (e) {
      log.w('update', 'Clearing web storage failed: $e');
    }
  }

  void reload() {
    log.i('update', 'Reloading page');
    web.window.location.reload();
  }

  // ---- High-level actions ---------------------------------------------------

  /// Re-checks for updates and reloads to pick up new assets.
  Future<MaintenanceResult> applyUpdate() async {
    await checkForUpdates();
    reload();
    return MaintenanceResult(true, 'Applying update...');
  }

  /// Clears all caches and reloads, leaving saved progress intact.
  Future<MaintenanceResult> clearCacheAndReload() async {
    final count = await clearCaches();
    reload();
    return MaintenanceResult(true, 'Cleared $count cache(s). Reloading...');
  }

  /// Obliterates everything — caches, service worker, web storage, and all
  /// saved Wordled data — then reloads to a first-run state.
  Future<MaintenanceResult> nuclearReset() async {
    log.w('update', '*** NUCLEAR RESET INITIATED ***');
    await _storage.wipeAll();
    final caches = await clearCaches();
    await unregisterServiceWorkers();
    clearWebStorage();
    log.w('update', 'Nuclear reset complete (cleared $caches caches). Reloading.');
    reload();
    return MaintenanceResult(true, 'Everything wiped. Starting over...');
  }
}
