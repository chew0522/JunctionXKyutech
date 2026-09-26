import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/floating_bottom_bar.dart';
import 'bookings_page.dart';
import 'bus_page.dart';
import 'cafe_page.dart';
import 'chat_screen.dart';
import 'courses_page.dart';
import 'dashboard_page.dart';
import 'events_page.dart';
import 'facilities_page.dart';
import 'healthcare_page.dart';
import 'profile_page.dart';
import 'scan_pay_page.dart';
import 'study_rooms_page.dart';
import 'timetable_page.dart';
import 'todo_list_page.dart';

// Chat is the app's default/launch tab per the product decision — note this differs
// from dashboard.md's own framing of the Dashboard as "the app's launch screen"; the
// Dashboard is still fully built to spec, it's just not what greets you on first open.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _dashboardKey = GlobalKey<DashboardPageState>();
  AppTab _active = AppTab.chat;

  void _navigate(AppTab tab) {
    setState(() => _active = tab);
    // See DashboardPageState.refresh's docstring — IndexedStack won't rebuild it on
    // its own, so returning to Home after booking something elsewhere would otherwise
    // show stale "Appointments" until a manual pull-to-refresh.
    if (tab == AppTab.home) _dashboardKey.currentState?.refresh();
  }

  // Every drill-in pops back to whichever tab was already showing underneath — that's
  // not a tab switch, so _navigate's refresh-on-Home logic never fires for it. Booking
  // or submitting something in any of these can change what Dashboard should show
  // (Appointments, the "Due next" tile), so each one refreshes it directly on the way out.
  void _popAndRefreshDashboard() {
    Navigator.of(context).pop();
    _dashboardKey.currentState?.refresh();
  }

  void _openHealthcarePage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HealthcarePage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openBusPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BusPage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openCafePage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CafePage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openEventsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventsPage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openTodoListPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TodoListPage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openTimetablePage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimetablePage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openScanPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanPayPage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openStudyRoomsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudyRoomsPage(onBack: _popAndRefreshDashboard)),
    );
  }

  void _openSchoolFacilitiesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacilitiesPage(
          title: 'School Facilities',
          category: 'event',
          icon: LucideIcons.landmark,
          onBack: _popAndRefreshDashboard,
        ),
      ),
    );
  }

  void _openSportsFacilitiesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacilitiesPage(
          title: 'Sports Facilities',
          category: 'sports',
          icon: LucideIcons.dumbbell,
          onBack: _popAndRefreshDashboard,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps every tab's state alive across switches (e.g. an in-progress
    // chat draft, or the Courses page's materials drill-in) instead of rebuilding it.
    return IndexedStack(
      index: AppTab.values.indexOf(_active),
      children: [
        DashboardPage(
          key: _dashboardKey,
          onNavigate: _navigate,
          onOpenBusPage: _openBusPage,
          onOpenCafePage: _openCafePage,
          onOpenEventsPage: _openEventsPage,
          onOpenTodoListPage: _openTodoListPage,
          onOpenTimetablePage: _openTimetablePage,
          onOpenScanPage: _openScanPage,
        ),
        CoursesPage(
          onNavigate: _navigate,
          onOpenTodoListPage: _openTodoListPage,
        ),
        ChatScreen(
          onGoHome: () => _navigate(AppTab.home),
        ),
        BookingsPage(
          onNavigate: _navigate,
          onOpenStudyRoomsPage: _openStudyRoomsPage,
          onOpenSchoolFacilitiesPage: _openSchoolFacilitiesPage,
          onOpenSportsFacilitiesPage: _openSportsFacilitiesPage,
          onOpenHealthcarePage: _openHealthcarePage,
        ),
        ProfilePage(onNavigate: _navigate),
      ],
    );
  }
}
