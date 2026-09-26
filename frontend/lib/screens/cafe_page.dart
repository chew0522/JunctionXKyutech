import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/page_header.dart';

const _crowdBars = {'low': 1, 'medium': 2, 'high': 3};

class CafePage extends StatefulWidget {
  final VoidCallback onBack;

  const CafePage({super.key, required this.onBack});

  @override
  State<CafePage> createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  final _api = ApiClient();
  List<dynamic>? _cafes;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final cafes = await _api.fetchCafes();
      cafes.sort((a, b) => a['wait_minutes'].compareTo(b['wait_minutes']));
      setState(() => _cafes = cafes);
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
            PageHeader(title: 'Cafes', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load cafe data.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_cafes == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final c in _cafes!) ...[
                              _CafeCard(cafe: c),
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

class _CafeCard extends StatelessWidget {
  final Map<String, dynamic> cafe;

  const _CafeCard({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final level = cafe['crowd_level'] as String;
    final filled = _crowdBars[level] ?? 1;
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.coffee, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cafe['name'], style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(cafe['location'], style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(3, (i) {
                  final barHeight = 8.0 + i * 4;
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      width: 5,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: i < filled ? AppColors.primary : AppColors.inputLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text('${level[0].toUpperCase()}${level.substring(1)} · ${cafe['wait_minutes']} min',
                  style: AppText.metaKey.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
