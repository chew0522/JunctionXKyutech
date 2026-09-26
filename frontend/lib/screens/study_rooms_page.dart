import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/bookable_card.dart';
import '../widgets/page_header.dart';

class StudyRoomsPage extends StatefulWidget {
  final VoidCallback onBack;

  const StudyRoomsPage({super.key, required this.onBack});

  @override
  State<StudyRoomsPage> createState() => _StudyRoomsPageState();
}

class _StudyRoomsPageState extends State<StudyRoomsPage> {
  final _api = ApiClient();
  List<dynamic>? _rooms;
  bool _errored = false;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final rooms = await _api.fetchRooms();
      setState(() => _rooms = rooms);
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  Future<void> _book(Map<String, dynamic> room) async {
    setState(() => _bookingId = room['id']);
    try {
      await _api.bookRoom(room['id']);
    } finally {
      await _load();
      setState(() => _bookingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Study Rooms', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load rooms.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_rooms == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            const SizedBox(height: 8),
                            for (final r in _rooms!) ...[
                              BookableResourceCard(
                                icon: LucideIcons.doorOpen,
                                title: r['name'],
                                subtitle: '${r['building']}, Floor ${r['floor']} · ${r['capacity']} seats'
                                    '${r['has_whiteboard'] == true ? ' · whiteboard' : ''}',
                                available: r['available'] == true,
                                booking: _bookingId == r['id'],
                                onBook: () => _book(r),
                              ),
                              const SizedBox(height: 10),
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
