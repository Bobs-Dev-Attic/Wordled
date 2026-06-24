import 'package:flutter/foundation.dart';

/// Non-web implementation of [InstallService]. A native build is already a
/// "real" installed app, so there's nothing to prompt; everything reports the
/// installed/standalone state. Kept API-compatible with the web version.
class InstallService {
  final ValueNotifier<bool> canInstall = ValueNotifier(false);

  void init() {}

  /// A native app is, by definition, already installed/standalone.
  bool get isStandalone => true;

  bool get isIOS => false;

  bool get hasPrompt => false;

  Future<bool> promptInstall() async => false;
}
