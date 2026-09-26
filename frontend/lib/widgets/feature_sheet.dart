import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

const _features = <(IconData, String, String)>[
  (LucideIcons.calendarDays, 'Events', "What's on today?"),
  (LucideIcons.bus, 'Bus', 'When is the next bus?'),
  (LucideIcons.checkSquare, 'To-dos', 'Show my to-dos'),
  (LucideIcons.coffee, 'Cafe crowd', 'How crowded are the cafes?'),
  (LucideIcons.doorOpen, 'Study room', 'Book a study room'),
  (LucideIcons.stethoscope, 'Clinic', 'Book a clinic appointment'),
  (LucideIcons.landmark, 'Facilities', 'What facilities can I book?'),
  (LucideIcons.graduationCap, 'Courses', 'What courses am I taking?'),
  (LucideIcons.footprints, 'Coffee run', 'Can I grab a coffee before my next class?'),
];

/// Bottom sheet of quick actions. Returns the prompt to send, or null if dismissed.
Future<String?> showFeatureSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What can I help with?', style: AppText.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                for (final (icon, name, prompt) in _features)
                  Material(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(prompt),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 24, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(name, style: AppText.button.copyWith(fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
