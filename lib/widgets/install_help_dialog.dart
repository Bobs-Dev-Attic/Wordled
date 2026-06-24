import 'package:flutter/material.dart';

/// Shows step-by-step install instructions appropriate to the platform. Used as
/// a fallback when no native install prompt is available (always on iOS, and on
/// desktop/Android browsers that haven't offered the prompt yet).
Future<void> showInstallHelp(BuildContext context, {required bool isIOS}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final steps = isIOS
          ? const [
              'Open this page in Safari (Chrome on iOS can\'t install apps).',
              'Tap the Share button (the square with an up arrow).',
              'Scroll down and tap "Add to Home Screen".',
              'Tap "Add" — Wordled appears on your home screen.',
            ]
          : const [
              'Open your browser\'s menu (⋮ or ☰).',
              'Tap "Install app" or "Add to Home screen".',
              'Confirm to add Wordled to your device.',
            ];
      return AlertDialog(
        title: const Text('Install Wordled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Wordled to your home screen to play it like a '
                'native app — fully offline.'),
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              ),
            if (!isIOS) ...[
              const SizedBox(height: 4),
              Text(
                'Don\'t see the option? Make sure you\'ve opened the site online '
                'once, interact with the page for a few seconds, then try again.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}
