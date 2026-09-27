import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

enum AppTab { home, courses, chat, bookings, profile }

class FloatingBottomBar extends StatelessWidget {
  final AppTab active;
  final void Function(AppTab) onTap;

  const FloatingBottomBar({
    super.key,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: 72 + 28, // extra headroom so the raised Ask button isn't clipped
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(36),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _tab(LucideIcons.home, 'Home', AppTab.home),
                  _tab(LucideIcons.graduationCap, 'Courses', AppTab.courses),
                  Expanded(
                    child: InkWell(
                      onTap: () => onTap(AppTab.chat),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            'Ask',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active == AppTab.chat ? FontWeight.w700 : FontWeight.w600,
                              color: active == AppTab.chat ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _tab(LucideIcons.calendarCheck, 'Bookings', AppTab.bookings),
                  _tab(LucideIcons.user, 'Profile', AppTab.profile),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => onTap(AppTab.chat),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 4),
                      ),
                      child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, AppTab tab) {
    final isActive = active == tab;
    final color = isActive ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(tab),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
