// Platform-agnostic entry point for the PWA install service. The web build
// captures `beforeinstallprompt`; native builds get a stub that reports the app
// as already installed (there's nothing to install).
export 'install_service_web.dart'
    if (dart.library.io) 'install_service_stub.dart';
