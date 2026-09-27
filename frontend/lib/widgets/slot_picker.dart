import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';

/// Calendar, then a grid of half-hour slots (unavailable ones greyed out).
/// Returns (yyyy-MM-dd, HH:mm), or null if cancelled.
Future<(String, String)?> pickDateTime(
  BuildContext context,
  DateTime now, {
  required String resourceId,
  required String name,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 60)),
  );
  if (date == null || !context.mounted) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  final dateStr = '${date.year}-${two(date.month)}-${two(date.day)}';
  final time = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (_) => _SlotSheet(resourceId: resourceId, name: name, date: dateStr),
  );
  return time == null ? null : (dateStr, time);
}

class _SlotSheet extends StatelessWidget {
  final String resourceId;
  final String name;
  final String date;

  const _SlotSheet({required this.resourceId, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: FutureBuilder<List<dynamic>>(
          future: ApiClient().fetchSlots(resourceId, name, date),
          builder: (context, snap) {
            if (snap.hasError) {
              return SizedBox(height: 120, child: Center(child: Text("Couldn't load times.", style: AppText.body)));
            }
            if (!snap.hasData) {
              return const SizedBox(
                  height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick a time · $date', style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Times marked "class" overlap a class. You can still book them after a warning.',
                    style: AppText.metaKey.copyWith(fontSize: 12)),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in snap.data!)
                          _SlotChip(
                            time: s['time'],
                            available: s['available'] == true,
                            note: s['class'] as String?,
                            onTap: () => Navigator.of(context).pop(s['time'] as String),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String time;
  final bool available;
  final String? note;
  final VoidCallback onTap;

  const _SlotChip({required this.time, required this.available, required this.onTap, this.note});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: available ? AppColors.primaryTint : AppColors.lineSoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: available ? onTap : null,
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: AppText.button.copyWith(
                  fontSize: 14,
                  color: available ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.6),
                  decoration: available ? null : TextDecoration.lineThrough,
                ),
              ),
              if (note != null)
                Text('class · $note', style: AppText.metaKey.copyWith(fontSize: 9, color: AppColors.danger)),
            ],
          ),
        ),
      ),
    );
  }
}
