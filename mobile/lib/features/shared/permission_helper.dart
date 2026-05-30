import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/haptics.dart';

class PermissionHelper {
  static Future<bool> requestCamera(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera permission required'),
          content: const Text(
            'Camera access was permanently denied. '
            'Open Settings to allow it.',
          ),
          actions: [
            TextButton(
              onPressed: () { Haptics.selectionClick(); Navigator.of(ctx).pop(); },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Haptics.selectionClick();
                Navigator.of(ctx).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return false;
  }
}
