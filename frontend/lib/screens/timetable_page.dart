import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/page_header.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class TimetablePage extends StatefulWidget {
  final VoidCallback onBack;

  const TimetablePage({super.key, required this.onBack});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final _api = ApiClient();
  List<dynamic>? _entries;
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
      final r = await Future.wait([_api.fetchTimetable(), _api.fetchNow()]);
      setState(() {
        _entries = r[0] as List;
        _now = r[1] as DateTime;
      });
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _days[_now.weekday - 1];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Course timetable', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(child: ElevatedButton(onPressed: _load, child: const Text('Try again')))
                  : _entries == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            for (final d in _days)
                              if (_entries!.any((e) => e['day'] == d)) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Text(
                                    d == today ? '$d · TODAY' : d,
                                    style: AppText.label.copyWith(
                                      color: d == today ? AppColors.primary : AppColors.textMuted,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                                for (final e in _entries!.where((e) => e['day'] == d)) _ClassCard(entry: e),
                              ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ClassCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['start'], style: AppText.metaValue.copyWith(fontSize: 14)),
                Text(entry['end'], style: AppText.metaKey.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(width: 3, height: 36, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry['code']} ${entry['name']}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.metaValue.copyWith(fontSize: 14)),
                Text('${entry['location']} · ${entry['room']}', style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
