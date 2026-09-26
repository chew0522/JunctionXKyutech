import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';

class ProfilePage extends StatefulWidget {
  final void Function(AppTab) onNavigate;
  final bool hasActiveNudge;

  const ProfilePage({super.key, required this.onNavigate, required this.hasActiveNudge});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiClient();
  int? _courseCount;
  int? _pendingCount;
  int? _eventCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.fetchCourses(),
        _api.fetchAssignments(pendingOnly: true),
        _api.fetchEvents(),
      ]);
      setState(() {
        _courseCount = results[0].length;
        _pendingCount = results[1].length;
        _eventCount = results[2].length;
      });
    } catch (_) {
      // Stats are a nice-to-have on this page — fail quietly.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Profile', onBack: () => widget.onNavigate(AppTab.home)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.user, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text('Alex', style: AppText.title.copyWith(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('Fall 2026 · Kyutech', style: AppText.body.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatTile(label: 'Courses', value: _courseCount)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(label: 'Pending', value: _pendingCount)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(label: 'Events', value: _eventCount)),
                    ],
                  ),
                  const SectionLabel('CAMPUS SERVICES'),
                  ListCard(rows: [
                    _row(LucideIcons.graduationCap, 'Courses', () => widget.onNavigate(AppTab.courses)),
                    _row(LucideIcons.calendarCheck, 'Bookings', () => widget.onNavigate(AppTab.bookings)),
                    _row(LucideIcons.messageCircle, 'Ask Campus Concierge', () => widget.onNavigate(AppTab.chat)),
                  ]),
                  const SectionLabel('ABOUT'),
                  ListCard(rows: [
                    _row(LucideIcons.info, 'Campus Concierge · v0.1', null),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            FloatingBottomBar(
              active: AppTab.profile,
              hasNudge: widget.hasActiveNudge,
              onTap: widget.onNavigate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.metaValue.copyWith(fontSize: 14))),
            if (onTap != null) const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int? value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value?.toString() ?? '—', style: AppText.cardTitle.copyWith(fontSize: 22, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppText.metaKey.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
