import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';
import '../widgets/bookable_card.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/page_header.dart';

class BookingsPage extends StatelessWidget {
  final void Function(AppTab) onNavigate;
  final VoidCallback onOpenStudyRoomsPage;
  final VoidCallback onOpenSchoolFacilitiesPage;
  final VoidCallback onOpenSportsFacilitiesPage;
  final VoidCallback onOpenHealthcarePage;

  const BookingsPage({
    super.key,
    required this.onNavigate,
    required this.onOpenStudyRoomsPage,
    required this.onOpenSchoolFacilitiesPage,
    required this.onOpenSportsFacilitiesPage,
    required this.onOpenHealthcarePage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Bookings', onBack: () => onNavigate(AppTab.home)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 4),
                  CategoryCard(
                    icon: LucideIcons.doorOpen,
                    title: 'Study Rooms',
                    subtitle: 'Library and Student Union rooms',
                    onTap: onOpenStudyRoomsPage,
                  ),
                  const SizedBox(height: 10),
                  CategoryCard(
                    icon: LucideIcons.landmark,
                    title: 'School Facilities',
                    subtitle: 'Halls, auditoriums, and event spaces',
                    onTap: onOpenSchoolFacilitiesPage,
                  ),
                  const SizedBox(height: 10),
                  CategoryCard(
                    icon: LucideIcons.dumbbell,
                    title: 'Sports Facilities',
                    subtitle: 'Courts, fields, and the gym',
                    onTap: onOpenSportsFacilitiesPage,
                  ),
                  const SizedBox(height: 10),
                  CategoryCard(
                    icon: LucideIcons.stethoscope,
                    title: 'Health Center',
                    subtitle: 'Book a clinic appointment',
                    onTap: onOpenHealthcarePage,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            FloatingBottomBar(
              active: AppTab.bookings,
              onTap: onNavigate,
            ),
          ],
        ),
      ),
    );
  }
}
