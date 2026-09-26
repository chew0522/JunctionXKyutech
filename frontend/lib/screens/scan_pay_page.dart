import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/page_header.dart';

const _tabs = ['Scan', 'Pay', 'ID'];
const _demoCodes = {'Attendance': 'attendance:CS301', 'Merit': 'merit:EVT-MERIT-1'};

class ScanPayPage extends StatefulWidget {
  final VoidCallback onBack;
  final int initialTab;

  const ScanPayPage({super.key, required this.onBack, this.initialTab = 0});

  @override
  State<ScanPayPage> createState() => _ScanPayPageState();
}

class _ScanPayPageState extends State<ScanPayPage> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Scan / Pay / ID', onBack: widget.onBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  children: [
                    for (int i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == _tab ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(_tabs[i],
                                style: AppText.button.copyWith(
                                    fontSize: 14, color: i == _tab ? Colors.white : AppColors.primary)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => const _ScanTab(),
                1 => const _QrTab(kind: 'pay'),
                _ => const _QrTab(kind: 'id'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final _api = ApiClient();
  final _controller = MobileScannerController();
  bool _handling = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _handle(String code) async {
    if (_handling) return;
    _handling = true;
    try {
      final res = await _api.scanCode(code);
      await _controller.stop();
      setState(() {
        _result = res;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = "Couldn't process that code. Try again.");
      _handling = false;
    }
  }

  Future<void> _scanAnother() async {
    setState(() {
      _result = null;
      _handling = false;
    });
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) return _resultView(result);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                      if (code != null) _handle(code);
                    },
                    errorBuilder: (context, error, child) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Camera unavailable. Allow camera access to scan.',
                            textAlign: TextAlign.center, style: AppText.body.copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_error ?? 'Scan an attendance or merit QR code.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: _error == null ? AppColors.textMuted : AppColors.text)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final e in _demoCodes.entries)
                ActionChip(
                  label: Text('Demo: ${e.key}'),
                  onPressed: () => _handle(e.value),
                  backgroundColor: AppColors.primaryTint,
                  side: BorderSide.none,
                  labelStyle: AppText.button.copyWith(fontSize: 12, color: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultView(Map<String, dynamic> r) {
    final ok = r['ok'] == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ok ? AppColors.primaryTint : const Color(0xFFFBE9E5),
                shape: BoxShape.circle,
              ),
              child: Icon(ok ? LucideIcons.check : LucideIcons.x,
                  size: 36, color: ok ? AppColors.primary : AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(r['title'], textAlign: TextAlign.center, style: AppText.title.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(r['detail'], textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _scanAnother, child: const Text('Scan another')),
          ],
        ),
      ),
    );
  }
}

class _QrTab extends StatefulWidget {
  final String kind; // 'pay' or 'id'

  const _QrTab({required this.kind});

  @override
  State<_QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<_QrTab> {
  final _api = ApiClient();
  Map<String, dynamic>? _qr;
  int _secondsLeft = 0;
  bool _errored = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_qr == null) return;
      if (_secondsLeft <= 1) {
        _refresh();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final qr = await _api.fetchQr(widget.kind);
      if (!mounted) return;
      setState(() {
        _qr = qr;
        _secondsLeft = qr['expires_in'] as int;
        _errored = false;
      });
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errored) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Couldn't load your code.", style: AppText.body),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _refresh, child: const Text('Try again')),
        ]),
      );
    }
    final qr = _qr;
    if (qr == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final qrBox = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: QrImageView(data: qr['code'], size: 220, padding: EdgeInsets.zero),
    );
    final refresh = Text('Refreshes in ${_secondsLeft}s',
        textAlign: TextAlign.center, style: AppText.metaKey.copyWith(fontSize: 13));

    if (widget.kind == 'pay') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(child: Text('Campus canteen payment', style: AppText.cardTitle.copyWith(fontSize: 18))),
          const SizedBox(height: 4),
          Center(
            child: Text('Show this code at the canteen counter.',
                style: AppText.body.copyWith(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 20),
          Center(child: qrBox),
          const SizedBox(height: 12),
          refresh,
          const SizedBox(height: 16),
          Text('Demo code — not connected to a real payment system.',
              textAlign: TextAlign.center, style: AppText.metaKey.copyWith(fontSize: 12)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Text('A', style: AppText.title.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(qr['name'], style: AppText.cardTitle.copyWith(color: Colors.white, fontSize: 18)),
                        Text(qr['matric'], style: AppText.body.copyWith(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${qr['programme']}\n${qr['faculty']}',
                    style: AppText.body.copyWith(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 18),
              qrBox,
              const SizedBox(height: 12),
              Text('Refreshes in ${_secondsLeft}s',
                  style: AppText.body.copyWith(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Demo ID — fictional data.', textAlign: TextAlign.center, style: AppText.metaKey.copyWith(fontSize: 12)),
      ],
    );
  }
}
