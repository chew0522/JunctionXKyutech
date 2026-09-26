import 'package:flutter/material.dart';

import '../theme.dart';

class TodoRow extends StatelessWidget {
  final String title;
  final String courseLabel;
  final String dueText;
  final bool isUrgent;
  final VoidCallback onTap;

  const TodoRow({
    super.key,
    required this.title,
    required this.courseLabel,
    required this.dueText,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textMuted, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.metaValue.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(courseLabel, style: AppText.metaKey.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(dueText,
                    style: AppText.button.copyWith(fontSize: 12, color: Colors.white)),
              )
            else
              Text(dueText, style: AppText.metaKey.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
