import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/dash_tile.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/nudge_card.dart';

class DashboardPage extends StatefulWidget {
  final void Function(AppTab) onNavigate;
  final VoidCallback onOpenBusPage;
  final VoidCallback onOpenCafePage;
  final VoidCallback onOpenEventsPage;
  final VoidCallback onOpenTodoListPage;
  // Nudges are fetched once, centrally, by MainShell — see its docstring for why.
  final List<Nudge> nudges;
  final bool hasActiveNudge;
  final void Function(String id, String label) onResolveNudge;

  const DashboardPage({
    super.key,
    required this.onNavigate,
    required this.onOpenBusPage,
    required this.onOpenCafePage,
    required this.onOpenEventsPage,
    required this.onOpenTodoListPage,
    required this.nudges,
    required this.hasActiveNudge,
    required this.onResolveNudge,
  });

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _api = ApiClient();
  bool _loading = true;
  bool _errored = false;

  DateTime _now = DateTime.now();
  List<dynamic> _bus = [];
  List<dynamic> _assignments = [];
  List<dynamic> _cafes = [];
  List<dynamic> _events = [];
  List<dynamic> _myBookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Called by MainShell when the Home tab is re-selected: IndexedStack keeps this
  // page's State alive across tab switches, so without this, booking something on
  // another tab (e.g. a facility) would never show up in "Appointments" until the
  // user pulled to refresh manually. No loading spinner here — it's a background
  // refresh of a page already on screen, not an initial load.
  Future<void> refresh() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    setState(() {
      _loading = _loading && !silent;
      _errored = false;
    });
    try {
      final results = await Future.wait([
        _api.fetchNow(),
        _api.fetchBus(),
        _api.fetchAssignments(pendingOnly: true),
        _api.fetchCafes(),
        _api.fetchEvents(),
        _api.fetchMyBookings(),
      ]);
      setState(() {
        _now = results[0] as DateTime;
        _bus = results[1] as List;
        _assignments = (results[2] as List)
          ..sort((a, b) => parseDateTime(a['due_date'], a['due_time'])
              .compareTo(parseDateTime(b['due_date'], b['due_time'])));
        _cafes = results[3] as List;
        final events = (results[4] as List)
            .where((e) => parseDateTime(e['date'], e['time']).isAfter(_now))
            .toList()
          ..sort((a, b) => parseDateTime(a['date'], a['time']).compareTo(parseDateTime(b['date'], b['time'])));
        _events = events.take(2).toList();
        _myBookings = (results[5] as List)
          ..sort((a, b) => parseDateTime(a['date'], a['time']).compareTo(parseDateTime(b['date'], b['time'])));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errored = true;
      });
    }
  }

  Nudge? get _currentNudge {
    for (final n in widget.nudges) {
      if (!n.resolved) return n;
    }
    return null;
  }

  String get _greeting {
    if (_now.hour < 12) return 'Good morning';
    if (_now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _errored
            ? _ErrorState(onRetry: _load)
            : Column(
                children: [
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : _content(),
                  ),
                  FloatingBottomBar(
                    active: AppTab.home,
                    hasNudge: widget.hasActiveNudge,
                    onTap: widget.onNavigate,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.inputLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Search campus…', style: AppText.body.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => widget.onNavigate(AppTab.profile),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('$_greeting, Alex', style: AppText.title.copyWith(fontSize: 26, height: 32 / 26)),
          const SizedBox(height: 4),
          Text("Here's your campus right now.", style: AppText.body.copyWith(color: AppColors.textMuted)),
          if (_currentNudge != null) ...[
            const SizedBox(height: 16),
            NudgeCard(
              nudge: _currentNudge!,
              compact: true,
              onButtonTap: (label) => widget.onResolveNudge(_currentNudge!.id, label),
            ),
          ],
          const SizedBox(height: 20),
          Text('RIGHT NOW', style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _busTile()),
              const SizedBox(width: 10),
              Expanded(child: _dueNextTile()),
              const SizedBox(width: 10),
              Expanded(child: _cafeTile()),
            ],
          ),
          if (_myBookings.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('APPOINTMENTS', style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
            const SizedBox(height: 8),
            for (final b in _myBookings) ...[
              _AppointmentCard(booking: b),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 20),
          Text('UPCOMING EVENTS', style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
          const SizedBox(height: 8),
          for (final e in _events) ...[
            EventPreviewCard(
              time: e['time'],
              name: e['name'],
              venue: e['venue'],
              organizer: e['organizer'],
              onTap: widget.onOpenEventsPage,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: widget.onOpenEventsPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTint,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('Show all events', style: AppText.button.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _busTile() {
    if (_bus.isEmpty) return const SizedBox();
    final route = _bus.first;
    return DashTile(
      icon: LucideIcons.bus,
      label: 'Next bus',
      value: '${route['eta_minutes']} min',
      line1: route['route'],
      line2: 'at the ${route['current_stop']}',
      onTap: widget.onOpenBusPage,
    );
  }

  Widget _dueNextTile() {
    if (_assignments.isEmpty) {
      return DashTile(
        icon: LucideIcons.checkSquare,
        label: 'Due next',
        value: '—',
        line1: 'All caught up',
        line2: '0 due',
        onTap: widget.onOpenTodoListPage,
      );
    }
    final first = _assignments.first;
    final due = parseDateTime(first['due_date'], first['due_time']);
    return DashTile(
      icon: LucideIcons.checkSquare,
      label: 'Due next',
      value: dueLabel(due, _now).text.split(' ').last,
      line1: first['title'],
      line2: '${isSameDay(due, _now) ? 'today' : weekdayShort(due)} · ${_assignments.length} due',
      onTap: widget.onOpenTodoListPage,
    );
  }

  Widget _cafeTile() {
    if (_cafes.isEmpty) return const SizedBox();
    const order = {'low': 0, 'medium': 1, 'high': 2};
    final sorted = [..._cafes]..sort((a, b) =>
        (order[a['crowd_level']] ?? 9).compareTo(order[b['crowd_level']] ?? 9));
    final best = sorted.first;
    final level = (best['crowd_level'] as String);
    return DashTile(
      icon: LucideIcons.coffee,
      label: 'Cafes',
      value: level[0].toUpperCase() + level.substring(1),
      line1: best['name'],
      line2: '${best['wait_minutes']} min wait',
      onTap: widget.onOpenCafePage,
    );
  }

}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _AppointmentCard({required this.booking});

  IconData get _icon => switch (booking['kind']) {
        'clinic' => LucideIcons.stethoscope,
        'facility' => LucideIcons.landmark,
        _ => LucideIcons.doorOpen,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                Text(booking['subtitle'], style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
          Text('${booking['date'].toString().substring(5)} · ${booking['time']}',
              style: AppText.metaKey.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load your dashboard.", style: AppText.body),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
