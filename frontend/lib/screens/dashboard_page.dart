import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/clash_dialog.dart';
import '../widgets/dash_tile.dart';
import '../widgets/slot_picker.dart';
import '../widgets/floating_bottom_bar.dart';

class DashboardPage extends StatefulWidget {
  final void Function(AppTab) onNavigate;
  final VoidCallback onOpenBusPage;
  final VoidCallback onOpenCafePage;
  final VoidCallback onOpenEventsPage;
  final VoidCallback onOpenTodoListPage;
  final VoidCallback onOpenTimetablePage;
  final VoidCallback onOpenScanPage;

  const DashboardPage({
    super.key,
    required this.onNavigate,
    required this.onOpenBusPage,
    required this.onOpenCafePage,
    required this.onOpenEventsPage,
    required this.onOpenTodoListPage,
    required this.onOpenTimetablePage,
    required this.onOpenScanPage,
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
  List<dynamic> _timetable = [];

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
        _api.fetchTimetable(),
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
          ..sort((a, b) => parseDateTime(a['date'], a['time'])
              .compareTo(parseDateTime(b['date'], b['time'])));
        _events = events.take(2).toList();
        _myBookings = (results[5] as List)
            .where((b) => !parseDateTime(b['date'], b['time']).isBefore(_now))
            .toList()
          ..sort((a, b) => parseDateTime(a['date'], a['time'])
              .compareTo(parseDateTime(b['date'], b['time'])));
        _timetable = results[6] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errored = true;
      });
    }
  }

  Future<void> _changeBooking(Map<String, dynamic> b) async {
    String message;
    if (b['kind'] == 'clinic') {
      final slots = (await _api.fetchClinicSlots())
          .where((s) =>
              s['available'] == true &&
              DateTime.parse('${s['date']} ${s['time']}').isAfter(_now))
          .toList();
      if (!mounted) return;
      final chosen = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                Text('Move your appointment',
                    style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                for (final s in slots)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        '${s['date'].toString().substring(5)} · ${s['time']}',
                        style: AppText.metaValue.copyWith(fontSize: 15)),
                    subtitle: Text('${s['doctor']} · ${s['type']}',
                        style: AppText.metaKey.copyWith(fontSize: 13)),
                    onTap: () =>
                        Navigator.of(ctx).pop(Map<String, dynamic>.from(s)),
                  ),
              ],
            ),
          ),
        ),
      );
      if (chosen == null || !mounted) return;
      final res = await bookWithClashCheck(
          context,
          (force) =>
              _api.changeBooking(b['id'], slotId: chosen['id'], force: force));
      message = res['cancelled'] == true ? '' : res['message'] as String;
    } else {
      final picked = await pickDateTime(context, _now,
          resourceId: b['resource_id'] ?? '', name: b['title']);
      if (picked == null || !mounted) return;
      final res = await bookWithClashCheck(
          context,
          (force) => _api.changeBooking(b['id'],
              date: picked.$1, time: picked.$2, force: force));
      message = res['cancelled'] == true ? '' : res['message'] as String;
    }
    if (!mounted) return;
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    await refresh();
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
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : _content(),
                  ),
                  FloatingBottomBar(
                    active: AppTab.home,
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
                child: GestureDetector(
                  onTap: () => widget.onNavigate(AppTab.chat),
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
                        const Icon(LucideIcons.search,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text('Ask or search campus…',
                            style: AppText.body
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => widget.onNavigate(AppTab.profile),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('$_greeting, Alex',
              style: AppText.title.copyWith(fontSize: 26, height: 32 / 26)),
          const SizedBox(height: 4),
          Text("Here's your campus right now.",
              style: AppText.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Text('RIGHT NOW',
              style: AppText.label
                  .copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _busTile()),
              const SizedBox(width: 10),
              Expanded(child: _dueNextTile()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _cafeTile()),
              const SizedBox(width: 10),
              Expanded(child: _timetableTile()),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.onOpenScanPage,
              icon: const Icon(LucideIcons.qrCode, size: 18),
              label: Text('Scan / Pay / ID',
                  style: AppText.button.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
          ),
          if (_myBookings.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('APPOINTMENTS',
                style: AppText.label
                    .copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
            const SizedBox(height: 8),
            for (final b in _myBookings) ...[
              _AppointmentCard(
                booking: b,
                onChange: b['kind'] == 'bus' ? null : () => _changeBooking(b),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 20),
          Text('UPCOMING EVENTS',
              style: AppText.label
                  .copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('Show all events',
                  style: AppText.button.copyWith(color: AppColors.primary)),
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
      value: due.isBefore(_now)
          ? 'Overdue'
          : dueLabel(due, _now).text.split(' ').last,
      line1: first['title'],
      line2:
          '${isSameDay(due, _now) ? 'today' : weekdayShort(due)} · ${_assignments.length} due',
      onTap: widget.onOpenTodoListPage,
    );
  }

  Widget _timetableTile() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = days[_now.weekday - 1];
    final nowStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final todays = _timetable.where((e) => e['day'] == today).toList()
      ..sort((a, b) => (a['start'] as String).compareTo(b['start'] as String));
    final upcoming = todays
        .where((e) => (e['end'] as String).compareTo(nowStr) > 0)
        .toList();
    final next = upcoming.isEmpty ? null : upcoming.first;
    return DashTile(
      icon: LucideIcons.calendarDays,
      label: 'Timetable',
      value: next == null ? '—' : next['start'],
      line1: next == null ? 'No more classes' : next['code'],
      line2:
          next == null ? 'today' : '${next['room']} · ${todays.length} today',
      onTap: widget.onOpenTimetablePage,
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
  final VoidCallback? onChange;

  const _AppointmentCard({required this.booking, this.onChange});

  IconData get _icon => switch (booking['kind']) {
        'clinic' => LucideIcons.stethoscope,
        'facility' => LucideIcons.landmark,
        'bus' => LucideIcons.bus,
        _ => LucideIcons.doorOpen,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
            decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['title'],
                    style: AppText.metaValue.copyWith(fontSize: 14)),
                Text(booking['subtitle'],
                    style: AppText.metaKey.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                    '${booking['date'].toString().substring(5)} · ${booking['time']}',
                    style: AppText.metaKey
                        .copyWith(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
          if (onChange != null)
            OutlinedButton(
              onPressed: onChange,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryLine),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('Change',
                  style: AppText.button
                      .copyWith(fontSize: 13, color: AppColors.primary)),
            ),
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
