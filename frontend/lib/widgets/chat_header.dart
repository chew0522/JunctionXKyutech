import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onHome;
  final bool showBorder;

  const ChatHeader({super.key, required this.onHome, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: showBorder ? AppColors.surface : AppColors.background,
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.line, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Back to dashboard',
            child: SizedBox(
              width: 44,
              height: 44,
              child: OutlinedButton(
                onPressed: onHome,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Icon(LucideIcons.home, size: 20, color: AppColors.text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Campus Concierge', style: AppText.appName),
        ],
      ),
    );
  }
}
