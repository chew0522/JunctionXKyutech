import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const PageHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppText.cardTitle.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
