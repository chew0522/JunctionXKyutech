import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/async_page.dart';
import '../widgets/list_card.dart';

String money(num v, String currency) {
  final neg = v < 0;
  final fixed = v.abs().toStringAsFixed(2).split('.');
  final whole = fixed[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '- ' : ''}$currency $whole.${fixed[1]}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _prettyDate(String iso) {
  final d = DateTime.parse(iso);
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

class MyFinancePage extends StatefulWidget {
  final VoidCallback onBack;

  const MyFinancePage({super.key, required this.onBack});

  @override
  State<MyFinancePage> createState() => _MyFinancePageState();
}

class _MyFinancePageState extends State<MyFinancePage> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final d = await _api.fetchFinance();
      setState(() => _data = d);
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncPage<Map<String, dynamic>>(
      title: 'MyFinance',
      onBack: widget.onBack,
      data: _data,
      errored: _errored,
      onRetry: _load,
      builder: (d) {
        final cur = d['currency'] as String;
        final outstanding = d['outstanding'] as num;
        Widget kv(String k, String v, {Color? color}) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(k, style: AppText.metaValue.copyWith(fontSize: 14))),
                  Text(v, style: AppText.metaValue.copyWith(fontSize: 14, color: color)),
                ],
              ),
            );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding balance', style: AppText.body.copyWith(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(money(outstanding, cur), style: AppText.display.copyWith(color: Colors.white, fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(outstanding > 0 ? 'Due by ${_prettyDate(d['due_date'])}' : 'Fully paid',
                      style: AppText.body.copyWith(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Total fees (${d['semester']})', value: money(d['total_fees'], cur))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Paid so far', value: money(d['paid'], cur), color: AppColors.success)),
              ],
            ),
            const SectionLabel('FEE BREAKDOWN'),
            ListCard(rows: [for (final f in d['fees']) kv(f['name'], money(f['amount'], cur))]),
            const SectionLabel('PAYMENT HISTORY'),
            ListCard(rows: [
              for (final p in d['payments'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: AppText.metaValue.copyWith(fontSize: 14)),
                            Text(_prettyDate(p['date']), style: AppText.metaKey.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(money(p['amount'], cur),
                          style: AppText.metaValue.copyWith(fontSize: 14, color: AppColors.success)),
                    ],
                  ),
                ),
            ]),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.metaKey.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: AppText.cardTitle.copyWith(fontSize: 16, color: color ?? AppColors.text)),
        ],
      ),
    );
  }
}
