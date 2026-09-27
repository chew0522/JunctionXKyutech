import 'package:flutter/material.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/clash_dialog.dart';
import '../widgets/page_header.dart';

class HealthcarePage extends StatefulWidget {
  final VoidCallback onBack;

  const HealthcarePage({super.key, required this.onBack});

  @override
  State<HealthcarePage> createState() => _HealthcarePageState();
}

class _HealthcarePageState extends State<HealthcarePage> {
  final _api = ApiClient();
  List<dynamic>? _slots;
  DateTime _now = DateTime.now();
  bool _errored = false;
  String? _bookingId;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final results = await Future.wait([_api.fetchNow(), _api.fetchClinicSlots()]);
      final slots = results[1] as List;
      slots.sort((a, b) => parseDateTime(a['date'], a['time']).compareTo(parseDateTime(b['date'], b['time'])));
      setState(() {
        _now = results[0] as DateTime;
        _selected ??= DateTime(_now.year, _now.month, _now.day);
        _slots = slots;
      });
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  Future<void> _book(Map<String, dynamic> slot) async {
    setState(() => _bookingId = slot['id']);
    try {
      await bookWithClashCheck(context, (force) => _api.bookClinicSlot(slot['id'], force: force));
    } finally {
      await _load();
      setState(() => _bookingId = null);
    }
  }

  List<dynamic> get _slotsForSelected =>
      _slots!.where((s) => isSameDay(DateTime.parse(s['date']), _selected!)).toList();

  String _dayLabel(DateTime date) {
    if (isSameDay(date, _now)) return 'Today';
    if (isTomorrow(date, _now)) return 'Tomorrow';
    return weekdayShort(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Health Center', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load clinic slots.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_slots == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Material(
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: AppColors.line),
                                borderRadius: BorderRadius.circular(AppRadius.card),
                              ),
                              child: CalendarDatePicker(
                                initialDate: _selected!,
                                firstDate: DateTime(_now.year, _now.month, _now.day),
                                lastDate: _now.add(const Duration(days: 60)),
                                onDateChanged: (d) => setState(() => _selected = d),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('${_dayLabel(_selected!)} · AVAILABLE TIMES'.toUpperCase(),
                                style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
                            const SizedBox(height: 8),
                            if (_slotsForSelected.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text('No appointments on this day.',
                                    style: AppText.body.copyWith(color: AppColors.textMuted)),
                              ),
                            for (final s in _slotsForSelected) ...[
                              _SlotCard(
                                slot: s,
                                booking: _bookingId == s['id'],
                                past: !parseDateTime(s['date'], s['time']).isAfter(_now),
                                onBook: () => _book(s),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  final bool booking;
  final bool past;
  final VoidCallback onBook;

  const _SlotCard({
    required this.slot,
    required this.past,
    required this.booking,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final available = slot['available'] == true && !past;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
            child: Text(slot['time'], style: AppText.button.copyWith(color: AppColors.primary, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot['doctor'], style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(slot['type'], style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: available
                ? ElevatedButton(
                    onPressed: booking ? null : onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    child: Text(booking ? '...' : 'Book', style: AppText.button.copyWith(color: Colors.white, fontSize: 13)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lineSoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(past ? 'Passed' : 'Booked', style: AppText.metaKey.copyWith(fontSize: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}
