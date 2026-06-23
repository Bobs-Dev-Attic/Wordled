import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'logger.dart';

/// Captures the browser's `beforeinstallprompt` event so the app can offer an
/// in-app "Install app" action (Add to Home Screen) for the PWA.
class InstallService {
  JSObject? _deferredPrompt;

  /// True when the browser has offered an installable prompt we can trigger.
  final ValueNotifier<bool> canInstall = ValueNotifier(false);

  void init() {
    try {
      web.window.addEventListener(
        'beforeinstallprompt',
        ((web.Event e) {
          e.preventDefault();
          _deferredPrompt = e as JSObject;
          canInstall.value = true;
          log.i('install', 'Install prompt available');
        }).toJS,
      );
      web.window.addEventListener(
        'appinstalled',
        ((web.Event e) {
          _deferredPrompt = null;
          canInstall.value = false;
          log.i('install', 'App installed');
        }).toJS,
      );
    } catch (e) {
      log.w('install', 'Install service init failed: $e');
    }
  }

  /// Whether the app is already running as an installed standalone PWA.
  bool get isStandalone {
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches ||
          web.window.matchMedia('(display-mode: fullscreen)').matches;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the native install prompt. Returns true if a prompt was shown.
  Future<bool> promptInstall() async {
    final prompt = _deferredPrompt;
    if (prompt == null) {
      log.w('install', 'No deferred install prompt to show');
      return false;
    }
    try {
      prompt.callMethod('prompt'.toJS);
      _deferredPrompt = null;
      canInstall.value = false;
      log.i('install', 'Install prompt shown');
      return true;
    } catch (e) {
      log.e('install', 'Failed to show install prompt: $e');
      return false;
    }
  }
}
