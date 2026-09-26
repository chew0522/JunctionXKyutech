import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../models.dart';
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
import 'study_rooms_page.dart';
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
  final _api = ApiClient();
  final _dashboardKey = GlobalKey<DashboardPageState>();
  AppTab _active = AppTab.chat;

  // Owned here, not per-tab: IndexedStack keeps every tab alive at once, so if each
  // screen polled /nudges independently they'd race the backend's deliver-once logic
  // and could double-fire the same nudge. One poller, one shared list, passed down.
  //
  // NOT final, and never mutated in place (always reassigned to a new list — see
  // _pollNudges): ChatScreen detects new nudges by comparing oldWidget.nudges against
  // widget.nudges in didUpdateWidget. If this stayed the same list object and were
  // just .add()-ed to, "old" and "new" would be the same reference by the time that
  // comparison runs, so the change would never be detected.
  List<Nudge> _nudges = [];
  final Set<String> _seenNudgeIds = {};
  Timer? _nudgeTimer;
  bool _pollInFlight = false;

  @override
  void initState() {
    super.initState();
    // _pollInFlight below guards against overlapping calls (e.g. the periodic timer
    // firing while a slow request is still out) hitting the deliver-once backend twice.
    _pollNudges();
    _nudgeTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollNudges());
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollNudges() async {
    if (_pollInFlight || !mounted) return;
    _pollInFlight = true;
    try {
      final fresh = await _api.fetchNudges();
      final unseen = fresh.where((n) => !_seenNudgeIds.contains(n.id)).toList();
      if (unseen.isEmpty) return;
      setState(() {
        _seenNudgeIds.addAll(unseen.map((n) => n.id));
        _nudges = [..._nudges, ...unseen];
      });
    } catch (_) {
      // Backend not reachable yet — ignore, the next tick will retry.
    } finally {
      _pollInFlight = false;
    }
  }

  void _resolveNudge(String id, String label) {
    setState(() {
      final nudge = _nudges.firstWhere((n) => n.id == id);
      nudge.resolved = true;
      nudge.chosenLabel = label;
    });
  }

  bool get _hasActiveNudge => _nudges.any((n) => !n.resolved);

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
          nudges: _nudges,
          hasActiveNudge: _hasActiveNudge,
          onResolveNudge: _resolveNudge,
        ),
        CoursesPage(
          onNavigate: _navigate,
          hasActiveNudge: _hasActiveNudge,
          onOpenTodoListPage: _openTodoListPage,
        ),
        ChatScreen(
          onGoHome: () => _navigate(AppTab.home),
          nudges: _nudges,
          onResolveNudge: _resolveNudge,
        ),
        BookingsPage(
          onNavigate: _navigate,
          onOpenStudyRoomsPage: _openStudyRoomsPage,
          onOpenSchoolFacilitiesPage: _openSchoolFacilitiesPage,
          onOpenSportsFacilitiesPage: _openSportsFacilitiesPage,
          onOpenHealthcarePage: _openHealthcarePage,
          hasActiveNudge: _hasActiveNudge,
        ),
        ProfilePage(onNavigate: _navigate, hasActiveNudge: _hasActiveNudge),
      ],
    );
  }
}
