// Platform-agnostic entry point for the update/cache service. The web build
// gets the real service-worker/cache implementation; native builds get a stub
// (no service worker exists there).
export 'maintenance_result.dart';
export 'update_service_web.dart'
    if (dart.library.io) 'update_service_stub.dart';
