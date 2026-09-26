import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class DashTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String line1;
  final String line2;
  final VoidCallback onTap;

  const DashTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.line1,
    required this.line2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: AppText.cardTitle.copyWith(fontSize: 22, color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line1,
                    style: AppText.metaValue.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    line2,
                    style: AppText.metaKey.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class EventPreviewCard extends StatelessWidget {
  final String time;
  final String name;
  final String venue;
  final String organizer;
  final VoidCallback onTap;

  const EventPreviewCard({
    super.key,
    required this.time,
    required this.name,
    required this.venue,
    required this.organizer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(time, style: AppText.cardTitle.copyWith(fontSize: 18, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.metaValue.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$venue · $organizer',
                        style: AppText.metaKey.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
