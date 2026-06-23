import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/logger.dart';

/// Displays the in-memory diagnostic log with copy/clear controls.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  @override
  void initState() {
    super.initState();
    log.addListener(_onLog);
  }

  @override
  void dispose() {
    log.removeListener(_onLog);
    super.dispose();
  }

  void _onLog() {
    if (mounted) setState(() {});
  }

  Color _levelColor(LogLevel level) => switch (level) {
        LogLevel.debug => Colors.blueGrey,
        LogLevel.info => Colors.teal,
        LogLevel.warn => Colors.orange,
        LogLevel.error => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final entries = log.entries.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Log',
            style: TextStyle(letterSpacing: 1, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: log.dump()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log copied to clipboard')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => log.clear(),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No log entries yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
              itemBuilder: (context, i) {
                final e = entries[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _levelColor(e.level).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(e.levelLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _levelColor(e.level))),
                    ),
                    Expanded(
                      child: Text(
                        '${e.tag}: ${e.message}',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
