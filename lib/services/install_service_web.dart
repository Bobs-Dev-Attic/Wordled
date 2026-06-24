import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'logger.dart';

// Helpers defined early in web/index.html, where the `beforeinstallprompt`
// event is captured before the Flutter engine boots.
@JS('pwaIsStandalone')
external bool _pwaIsStandalone();
@JS('pwaInstallAvailable')
external bool _pwaInstallAvailable();
@JS('pwaPromptInstall')
external JSPromise<JSString> _pwaPromptInstall();

/// Web implementation: defers to the JS install helpers in index.html. The
/// install prompt must be captured in plain JS at page load (Chrome fires
/// `beforeinstallprompt` before Dart's `main()` runs), so this class only reads
/// and triggers it.
class InstallService {
  /// Unused on web (state is read live from JS); kept for API parity.
  final ValueNotifier<bool> canInstall = ValueNotifier(false);

  void init() {}

  /// Whether the app is already running as an installed standalone PWA.
  bool get isStandalone {
    try {
      return _pwaIsStandalone();
    } catch (_) {
      return false;
    }
  }

  /// True on iOS/iPadOS, where there is no install prompt — the user must use
  /// Safari's Share → "Add to Home Screen".
  bool get isIOS {
    try {
      final nav = web.window.navigator;
      final ua = nav.userAgent.toLowerCase();
      if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
        return true;
      }
      return ua.contains('macintosh') && nav.maxTouchPoints > 1;
    } catch (_) {
      return false;
    }
  }

  /// Whether a native install prompt was captured and can be triggered.
  bool get hasPrompt {
    try {
      return _pwaInstallAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Triggers the captured install prompt. Returns true if the user accepted.
  Future<bool> promptInstall() async {
    if (!hasPrompt) {
      log.w('install', 'No deferred install prompt to show');
      return false;
    }
    try {
      final outcome = (await _pwaPromptInstall().toDart).toDart;
      log.i('install', 'Install prompt outcome: $outcome');
      return outcome == 'accepted';
    } catch (e) {
      log.e('install', 'Failed to show install prompt: $e');
      return false;
    }
  }
}
