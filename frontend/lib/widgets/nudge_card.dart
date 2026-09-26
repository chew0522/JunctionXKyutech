import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models.dart';
import '../theme.dart';

IconData _pillIcon(String name) {
  switch (name) {
    case 'map-pin':
      return LucideIcons.mapPin;
    case 'users':
      return LucideIcons.users;
    case 'clock':
      return LucideIcons.clock;
    default:
      return LucideIcons.info;
  }
}

class NudgeCard extends StatefulWidget {
  final Nudge nudge;
  final void Function(String buttonLabel) onButtonTap;
  // Dashboard uses the compact form (no pills) — see dashboard.md's "Nudge card (compact)".
  final bool compact;

  const NudgeCard({
    super.key,
    required this.nudge,
    required this.onButtonTap,
    this.compact = false,
  });

  @override
  State<NudgeCard> createState() => _NudgeCardState();
}

class _NudgeCardState extends State<NudgeCard> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  void _handleTap(String label) {
    setState(() {
      widget.nudge.resolved = true;
      widget.nudge.chosenLabel = label;
    });
    widget.onButtonTap(label);
  }

  @override
  Widget build(BuildContext context) {
    final nudge = widget.nudge;

    if (nudge.resolved) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0.6),
        duration: const Duration(milliseconds: 200),
        builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(LucideIcons.check, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${nudge.title} · You chose "${nudge.chosenLabel}"',
                  style: AppText.body.copyWith(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.15), end: Offset.zero),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, offset, child) => FractionalTranslation(translation: offset, child: child),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.nudgeFill,
          border: Border.all(color: AppColors.nudgeLine),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bell, size: 16, color: AppColors.nudge),
                const SizedBox(width: 6),
                Text('HEADS UP', style: AppText.label),
                const Spacer(),
                Text(
                  "You didn't ask — I noticed",
                  style: AppText.label.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(nudge.title, style: AppText.title),
            const SizedBox(height: 4),
            Text(nudge.body, style: AppText.body),
            if (!widget.compact && nudge.pills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nudge.pills.map((p) {
                  return Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_pillIcon(p.icon), size: 14, color: AppColors.nudge),
                        const SizedBox(width: 6),
                        Text(p.text, style: AppText.metaValue.copyWith(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: nudge.buttons.asMap().entries.map((entry) {
                final button = entry.value;
                final isPrimary = button.style == 'primary';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: entry.key == 0 ? 8 : 0),
                    child: SizedBox(
                      height: 44,
                      child: isPrimary
                          ? ElevatedButton(
                              onPressed: () => _handleTap(button.label),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.nudge,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button),
                                ),
                              ),
                              child: Text(button.label, style: AppText.button),
                            )
                          : OutlinedButton(
                              onPressed: () => _handleTap(button.label),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.nudge,
                                side: const BorderSide(color: AppColors.nudgeButtonLine),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.button),
                                ),
                              ),
                              child: Text(button.label, style: AppText.button.copyWith(color: AppColors.nudge)),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
