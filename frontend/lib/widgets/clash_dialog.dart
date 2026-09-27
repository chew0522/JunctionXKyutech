import 'package:flutter/material.dart';

import '../theme.dart';

/// Runs a booking call; if the backend says it overlaps a class, asks the student to confirm
/// and retries with force. A cancelled confirmation comes back as {'success': false, 'cancelled': true}.
Future<Map<String, dynamic>> bookWithClashCheck(
  BuildContext context,
  Future<Map<String, dynamic>> Function(bool force) call,
) async {
  final res = await call(false);
  if (res['needs_confirmation'] != true || !context.mounted) return res;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('You have class then', style: AppText.cardTitle.copyWith(fontSize: 18)),
      content: Text(res['message'] as String, style: AppText.body),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Pick another time')),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Book anyway'),
        ),
      ],
    ),
  );
  if (ok != true) return {'success': false, 'cancelled': true};
  return call(true);
}
