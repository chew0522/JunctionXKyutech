import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/page_header.dart';

class BusPage extends StatefulWidget {
  final VoidCallback onBack;

  const BusPage({super.key, required this.onBack});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final _api = ApiClient();
  List<dynamic>? _routes;
  DateTime _now = DateTime.now();
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final results = await Future.wait([_api.fetchNow(), _api.fetchBus()]);
      setState(() {
        _now = results[0] as DateTime;
        _routes = results[1] as List;
      });
    } catch (_) {
      setState(() => _errored = true);
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
                  : (_routes == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final r in _routes!) ...[
                              _RouteCard(route: r, now: _now),
                              const SizedBox(height: 12),
                            ],
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final DateTime now;

  const _RouteCard({required this.route, required this.now});

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
        border: Border.all(color: AppColors.line),
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
