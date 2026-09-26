import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/bookable_card.dart';
import '../widgets/page_header.dart';

class FacilitiesPage extends StatefulWidget {
  final String title;
  final String category; // "event" or "sports" — see data/facilities.json
  final IconData icon;
  final VoidCallback onBack;

  const FacilitiesPage({
    super.key,
    required this.title,
    required this.category,
    required this.icon,
    required this.onBack,
  });

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  final _api = ApiClient();
  List<dynamic>? _facilities;
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
      final facilities = await _api.fetchFacilities(category: widget.category);
      setState(() => _facilities = facilities);
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  Future<void> _book(Map<String, dynamic> facility) async {
    setState(() => _bookingId = facility['id']);
    try {
      await _api.bookFacility(facility['id']);
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
            PageHeader(title: widget.title, onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load ${widget.title.toLowerCase()}.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_facilities == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            const SizedBox(height: 8),
                            for (final f in _facilities!) ...[
                              BookableResourceCard(
                                icon: widget.icon,
                                title: f['name'],
                                subtitle: '${f['location']} · Capacity ${f['capacity']}',
                                available: f['available'] == true,
                                booking: _bookingId == f['id'],
                                onBook: () => _book(f),
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
