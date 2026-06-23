import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Severity levels for log entries.
enum LogLevel { debug, info, warn, error }

/// A single timestamped log line.
class LogEntry {
  LogEntry(this.level, this.tag, this.message) : time = DateTime.now();

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  String get _stamp {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${three(time.millisecond)}';
  }

  String get levelLabel => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
      };

  @override
  String toString() => '$_stamp [$levelLabel] $tag: $message';
}

/// App-wide verbose logger. Mirrors entries to the dev console and keeps a
/// bounded in-memory ring buffer so the log can be shown (and copied) inside
/// the app — useful for diagnosing the update/cache system in the field.
class AppLogger extends ChangeNotifier {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int _maxEntries = 500;
  final ListQueue<LogEntry> _entries = ListQueue<LogEntry>();

  /// Whether verbose debug-level logging is emitted. Defaults to on.
  bool verbose = true;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void log(LogLevel level, String tag, String message) {
    if (level == LogLevel.debug && !verbose) return;
    final entry = LogEntry(level, tag, message);
    _entries.addLast(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    // Surface everything to the browser/dev console as well.
    debugPrint(entry.toString());
    notifyListeners();
  }

  void d(String tag, String message) => log(LogLevel.debug, tag, message);
  void i(String tag, String message) => log(LogLevel.info, tag, message);
  void w(String tag, String message) => log(LogLevel.warn, tag, message);
  void e(String tag, String message) => log(LogLevel.error, tag, message);

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// The full log as plain text, oldest first.
  String dump() => _entries.map((e) => e.toString()).join('\n');
}

/// Convenience global.
final log = AppLogger.instance;
