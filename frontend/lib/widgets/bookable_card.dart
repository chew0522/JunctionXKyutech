import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

class BookableResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;
  final bool booking;
  final VoidCallback onBook;
  final String actionLabel;

  const BookableResourceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.booking,
    required this.onBook,
    this.actionLabel = 'Book',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: available
                ? ElevatedButton(
                    onPressed: booking ? null : onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    child: Text(booking ? '...' : actionLabel,
                        style: AppText.button.copyWith(color: Colors.white, fontSize: 13)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lineSoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text('Booked', style: AppText.metaKey.copyWith(fontSize: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.metaKey.copyWith(fontSize: 13)),
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

enum ProposalStatus { idle, booking, booked }

/// A concrete booking the assistant proposed (resource + date + time). Confirm books exactly
/// these details; the model never chooses at confirm time.
class BookingProposalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ProposalStatus status;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  const BookingProposalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onConfirm,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final booked = status == ProposalStatus.booked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: booked ? AppColors.success : AppColors.line, width: booked ? 1.5 : 1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.metaKey.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (booked)
            Container(
              width: double.infinity,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.successFill, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('Booked', style: AppText.button.copyWith(color: AppColors.success)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: status == ProposalStatus.booking ? null : onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      child: Text(status == ProposalStatus.booking ? '...' : 'Confirm booking',
                          style: AppText.button.copyWith(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: status == ProposalStatus.booking ? null : onChange,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryLine),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    child: Text('Change time', style: AppText.button.copyWith(color: AppColors.primary, fontSize: 14)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
