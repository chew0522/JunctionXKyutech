import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/page_header.dart';

class EventsPage extends StatefulWidget {
  final VoidCallback onBack;

  const EventsPage({super.key, required this.onBack});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _api = ApiClient();
  List<dynamic>? _events;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final events = await _api.fetchEvents();
      events.sort((a, b) => parseDateTime(a['date'], a['time']).compareTo(parseDateTime(b['date'], b['time'])));
      setState(() => _events = events);
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
            PageHeader(title: 'Events', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load events.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_events == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final e in _events!) ...[
                              _EventCard(event: e),
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

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['time'], style: AppText.cardTitle.copyWith(fontSize: 16, color: AppColors.primary)),
                Text(event['date'].toString().substring(5), style: AppText.metaKey.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['name'], style: AppText.metaValue.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(event['description'], style: AppText.body.copyWith(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${event['venue']} · ${event['organizer']}',
                          style: AppText.metaKey.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
