import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/campus_map.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';

class BusPage extends StatefulWidget {
  final VoidCallback onBack;
  // Set when opened from a chat card: track this bus and show the trip it was offered for.
  final String? initialBusId;
  final String? initialFromId;
  final String? initialToId;

  const BusPage({super.key, required this.onBack, this.initialBusId, this.initialFromId, this.initialToId});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final _api = ApiClient();
  Map<String, dynamic>? _campus;
  List<dynamic> _buses = [];
  DateTime _now = DateTime.now();
  bool _errored = false;
  Timer? _timer;

  int _tab = 0; // 0 = plan trip, 1 = all buses
  String? _selectedBusId;
  String? _fromId;
  String? _toId;
  Map<String, dynamic>? _plan;
  bool _planning = false;
  String? _schedulingRoute;
  String? _scheduledRoute;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _pollBuses());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final r = await Future.wait([_api.fetchNow(), _api.fetchCampusMap(), _api.fetchBus(), _api.fetchMyLocation()]);
      final first = _campus == null;
      setState(() {
        _now = r[0] as DateTime;
        _campus = r[1] as Map<String, dynamic>;
        _buses = r[2] as List;
        if (first) {
          _fromId = widget.initialFromId ?? (r[3] as Map<String, dynamic>)['building_id'];
          _toId = widget.initialToId;
          _selectedBusId = widget.initialBusId;
          _tab = 0;
        }
      });
      if (first && _fromId != null && _toId != null) _findBuses();
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  Future<void> _pollBuses() async {
    if (_campus == null || !mounted) return;
    try {
      final buses = await _api.fetchBus();
      if (mounted) setState(() => _buses = buses);
    } catch (_) {
      // Next tick retries.
    }
  }

  List get _buildings => (_campus!['buildings'] as List);

  String _nameOf(String id) => _buildings.firstWhere((b) => b['id'] == id)['name'];

  Future<void> _pickPlace({required bool isFrom}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              Text(isFrom ? 'Where are you?' : 'Where to?', style: AppText.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              for (final b in _buildings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                  ),
                  title: Text(b['name'], style: AppText.metaValue.copyWith(fontSize: 15)),
                  onTap: () => Navigator.of(ctx).pop(b['id'] as String),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromId = picked;
      } else {
        _toId = picked;
      }
      _scheduledRoute = null;
    });
    _findBuses();
  }

  void _swap() {
    setState(() {
      final t = _fromId;
      _fromId = _toId;
      _toId = t;
      _scheduledRoute = null;
    });
    _findBuses();
  }

  Future<void> _findBuses() async {
    final from = _fromId;
    final to = _toId;
    if (from == null || to == null) {
      setState(() => _plan = null);
      return;
    }
    setState(() => _planning = true);
    try {
      final plan = await _api.fetchTripPlan(from, to);
      if (from == _fromId && to == _toId) setState(() => _plan = plan);
    } catch (_) {
      setState(() => _plan = {'error': "Couldn't load bus options.", 'options': []});
    } finally {
      setState(() => _planning = false);
    }
  }

  Future<void> _schedule(Map<String, dynamic> option) async {
    setState(() => _schedulingRoute = option['route_id']);
    try {
      final res = await _api.scheduleTrip(option['route_id'], _fromId!, _toId!);
      if (res['success'] == true) setState(() => _scheduledRoute = option['route_id']);
    } finally {
      setState(() => _schedulingRoute = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Buses', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load bus data.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_campus == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _content()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        CampusMapView(
          campus: _campus!,
          buses: _buses,
          fromId: _fromId,
          toId: _toId,
          selectedBusId: _selectedBusId,
          onBusTap: (id) => setState(() => _selectedBusId = _selectedBusId == id ? null : id),
        ),
        const SizedBox(height: 10),
        _legend(),
        if (_selectedBusId != null && _tab == 0) ...[
          const SizedBox(height: 10),
          _RouteCard(route: _buses.firstWhere((b) => b['id'] == _selectedBusId), now: _now),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(
            children: [
              for (final (i, label) in const [(1, 'All buses'), (0, 'Plan a trip')])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _tab == i ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(label,
                          style: AppText.button.copyWith(fontSize: 14, color: _tab == i ? Colors.white : AppColors.primary)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_tab == 0) _planner() else _allBuses(),
      ],
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (int i = 0; i < _buses.length; i++)
          GestureDetector(
            onTap: () => setState(() => _selectedBusId = _selectedBusId == _buses[i]['id'] ? null : _buses[i]['id']),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: busColor(i), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_buses[i]['route'], style: AppText.metaKey.copyWith(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeField({required String label, required String? id, required bool isFrom}) {
    return InkWell(
      onTap: () => _pickPlace(isFrom: isFrom),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: isFrom ? AppColors.success : AppColors.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.metaKey.copyWith(fontSize: 11)),
                  Text(id == null ? 'Choose a place' : _nameOf(id),
                      style: AppText.metaValue.copyWith(fontSize: 15, color: id == null ? AppColors.textMuted : AppColors.text)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _planner() {
    final options = (_plan?['options'] as List?) ?? [];
    final error = _plan?['error'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _placeField(label: 'From', id: _fromId, isFrom: true),
                  const SizedBox(height: 8),
                  _placeField(label: 'To', id: _toId, isFrom: false),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _fromId != null && _toId != null ? _swap : null,
              icon: const Icon(LucideIcons.arrowUpDown, size: 20),
              color: AppColors.primary,
            ),
          ],
        ),
        if (_planning)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_plan == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Pick where you are and where you want to go to see available buses.',
                style: AppText.body.copyWith(color: AppColors.textMuted)),
          )
        else ...[
          SectionLabel(options.isEmpty ? 'NO BUSES' : 'AVAILABLE BUSES'),
          if (options.isEmpty)
            Text(error ?? 'No buses found.', style: AppText.body.copyWith(color: AppColors.textMuted)),
          for (final o in options) ...[
            _tripCard(o),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _tripCard(Map<String, dynamic> o) {
    final index = _buses.indexWhere((b) => b['id'] == o['route_id']);
    final scheduled = _scheduledRoute == o['route_id'];
    final wait = o['wait_minutes'] as int;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: busColor(index < 0 ? 0 : index), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(o['route'], style: AppText.cardTitle.copyWith(fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.lineSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(o['plate_number'], style: AppText.metaKey.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(wait == 0 ? 'Now' : '$wait min', 'until it arrives'),
              _stat('${o['ride_minutes']} min', 'ride'),
              _stat(o['arrive_at'], 'you arrive'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Next one after that leaves at ${o['next_depart_at']}.',
              style: AppText.metaKey.copyWith(fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: scheduled || _schedulingRoute != null ? null : () => _schedule(o),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: scheduled ? AppColors.successFill : AppColors.lineSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text(
                scheduled ? 'Scheduled for ${o['depart_at']}' : (_schedulingRoute == o['route_id'] ? '...' : 'Schedule this bus'),
                style: AppText.button.copyWith(color: scheduled ? AppColors.success : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.cardTitle.copyWith(fontSize: 18, color: AppColors.primary)),
            Text(label, style: AppText.metaKey.copyWith(fontSize: 11)),
          ],
        ),
      );

  Widget _allBuses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedBusId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedBusId = null),
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('Show all routes'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Tap a bus to see only its route on the map.',
                style: AppText.metaKey.copyWith(fontSize: 13)),
          ),
        for (final r in _buses) ...[
          GestureDetector(
            onTap: () => setState(() => _selectedBusId = _selectedBusId == r['id'] ? null : r['id']),
            child: _RouteCard(route: r, now: _now, selected: _selectedBusId == r['id']),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final DateTime now;
  final bool selected;

  const _RouteCard({required this.route, required this.now, this.selected = false});

  String get _updatedLabel {
    final updated = DateTime.tryParse(route['last_updated'] ?? '');
    if (updated == null) return '';
    final minutes = now.difference(updated).inMinutes;
    if (minutes <= 0) return 'Updated just now';
    if (minutes == 1) return 'Updated 1 min ago';
    return 'Updated $minutes min ago';
  }

  @override
  Widget build(BuildContext context) {
    final crowd = route['capacity_status'] as String;
    final stops = (route['stops'] as List?)?.cast<String>() ?? [];
    final currentStop = route['current_stop'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 2 : 1),
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
                child: const Icon(LucideIcons.bus, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            route['route'],
                            style: AppText.cardTitle.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lineSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(route['plate_number'] ?? '', style: AppText.metaKey.copyWith(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${crowd[0].toUpperCase()}${crowd.substring(1)} · $currentStop → ${route['next_stop']}',
                        style: AppText.metaKey.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${route['eta_minutes']} min', style: AppText.cardTitle.copyWith(fontSize: 20, color: AppColors.primary)),
                  Text('ETA', style: AppText.metaKey.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
          if (stops.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lineSoft),
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < stops.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: stops[i] == currentStop ? 12 : 8,
                          height: stops[i] == currentStop ? 12 : 8,
                          decoration: BoxDecoration(
                            color: stops[i] == currentStop ? AppColors.primary : AppColors.inputLine,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stops[i],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.metaKey.copyWith(
                            fontSize: 10,
                            color: stops[i] == currentStop ? AppColors.primary : AppColors.textMuted,
                            fontWeight: stops[i] == currentStop ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < stops.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(width: 16, height: 2, color: AppColors.inputLine),
                    ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(_updatedLabel, style: AppText.metaKey.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
