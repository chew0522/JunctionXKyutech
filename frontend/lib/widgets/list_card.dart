import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class ListCard extends StatelessWidget {
  final List<Widget> rows;

  const ListCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.lineSoft),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  // Optional '>' affordance for "see more" — e.g. the Courses page's to-do section
  // linking to the full To-Do List page.
  final VoidCallback? onTap;

  const SectionLabel(this.text, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7),
    );

    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 8, top: 20), child: label);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: label),
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
