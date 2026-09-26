import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class NoticeBanner extends StatelessWidget {
  final String text;

  const NoticeBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DC),
        border: Border.all(color: const Color(0xFFF2C98B)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertTriangle, size: 18, color: AppColors.nudge),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 14, color: AppColors.nudge))),
        ],
      ),
    );
  }
}
