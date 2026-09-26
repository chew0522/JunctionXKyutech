import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/async_page.dart';
import '../widgets/list_card.dart';
import '../widgets/notice_banner.dart';
import '../widgets/page_header.dart';

const _tabs = ['Course Registration', 'Courses Dropped', 'Exemptions'];

class MyRegisterPage extends StatefulWidget {
  final VoidCallback onBack;

  const MyRegisterPage({super.key, required this.onBack});

  @override
  State<MyRegisterPage> createState() => _MyRegisterPageState();
}

class _MyRegisterPageState extends State<MyRegisterPage> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _errored = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final d = await _api.fetchRegistration();
      setState(() => _data = d);
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
            PageHeader(title: 'MyRegister', onBack: widget.onBack),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Material(
                  color: i == _tab ? AppColors.primary : AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(_tabs[i],
                          style: AppText.button.copyWith(
                              fontSize: 14, color: i == _tab ? Colors.white : AppColors.primary)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_errored) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Couldn't load registration.", style: AppText.body),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Try again')),
        ]),
      );
    }
    final d = _data;
    if (d == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return ListView(
      key: ValueKey(_tab),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        switch (_tab) {
          0 => _registration(d),
          1 => _dropped(d['dropped']),
          _ => _exemptions(d['exemptions']),
        },
      ],
    );
  }

  Widget _registration(Map<String, dynamic> d) {
    final open = d['registration_open'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!open) const NoticeBanner('You are not allowed to register any course — registration period is closed.'),
        Row(
          children: [
            const Expanded(child: SectionLabel('LIST OF COURSES REGISTERED')),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AddCoursePage(data: d, onBack: () => Navigator.of(ctx).pop()),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primaryTint,
                side: const BorderSide(color: AppColors.primaryLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('+ Add course', style: AppText.button.copyWith(fontSize: 13, color: AppColors.primary)),
            ),
          ],
        ),
        ListCard(rows: [
          for (final c in d['registered'])
            _courseRow('${c['code']} — ${c['name']}', '${c['credits']} credit hours · ${c['venue']}',
                trailing: const _Pill(text: 'Registered', fill: AppColors.successFill, color: AppColors.success)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: Row(
            children: [
              Expanded(child: Text('Total credit hours', style: AppText.metaKey.copyWith(fontSize: 14))),
              Text('${d['total_credits']}', style: AppText.cardTitle.copyWith(fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropped(List items) {
    if (items.isEmpty) return _empty('No dropped courses.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('COURSES DROPPED'),
        ListCard(rows: [
          for (final c in items)
            _courseRow('${c['code']} — ${c['name']}', '${c['credits']} credit hours · Dropped ${c['dropped_on']} · ${c['reason']}',
                trailing: const _Pill(text: 'Dropped', fill: Color(0xFFFBE9E5), color: AppColors.danger)),
        ]),
      ],
    );
  }

  Widget _exemptions(List items) {
    if (items.isEmpty) return _empty('No exemptions.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('EXEMPTIONS'),
        ListCard(rows: [
          for (final c in items)
            _courseRow('${c['code']} — ${c['name']}', '${c['credits']} credit hours · ${c['reason']}',
                trailing: const _Pill(text: 'Exempted', fill: AppColors.primaryTint, color: AppColors.primary)),
        ]),
      ],
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: AppText.body.copyWith(color: AppColors.textMuted)),
      );
}

Widget _courseRow(String title, String subtitle, {required Widget trailing}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.metaValue.copyWith(fontSize: 14)),
                Text(subtitle, style: AppText.metaKey.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );

class _Pill extends StatelessWidget {
  final String text;
  final Color fill;
  final Color color;

  const _Pill({required this.text, required this.fill, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(text, style: AppText.button.copyWith(fontSize: 12, color: color)),
      );
}

class AddCoursePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onBack;

  const AddCoursePage({super.key, required this.data, required this.onBack});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final open = widget.data['registration_open'] == true;
    final q = _query.trim().toLowerCase();
    final courses = (widget.data['available'] as List)
        .where((c) => q.isEmpty || '${c['code']} ${c['name']}'.toLowerCase().contains(q))
        .toList();
    return AsyncPage<List>(
      title: 'Add Course',
      onBack: widget.onBack,
      data: courses,
      errored: false,
      onRetry: () {},
      builder: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (!open) const NoticeBanner('Registration period is closed — you can browse courses but not add them.'),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.inputLine),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: AppText.body,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'Search by course code or name…',
                      hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('AVAILABLE THIS SEMESTER'),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No matching courses.', style: AppText.body.copyWith(color: AppColors.textMuted)),
            ),
          for (final c in list) ...[
            _AvailableCourseCard(course: c, registrationOpen: open),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AvailableCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool registrationOpen;

  const _AvailableCourseCard({required this.course, required this.registrationOpen});

  @override
  Widget build(BuildContext context) {
    final eligible = course['eligible'] == true;
    final canAdd = eligible && registrationOpen;
    final color = eligible ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eligible ? AppColors.surface : const Color(0xFFFAF9F6),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${course['code']} — ${course['name']}',
                    style: AppText.cardTitle.copyWith(fontSize: 16, color: eligible ? AppColors.text : AppColors.textMuted)),
              ),
              _Pill(
                text: eligible ? 'Eligible' : 'Not eligible',
                fill: eligible ? AppColors.successFill : const Color(0xFFFBE9E5),
                color: color,
              ),
            ],
          ),
          Text('${course['instructor']} · ${course['credits']} credit hours', style: AppText.metaKey.copyWith(fontSize: 13)),
          const Divider(height: 22, color: AppColors.lineSoft),
          _line(LucideIcons.calendar, course['schedule']),
          const SizedBox(height: 6),
          _line(LucideIcons.mapPin, course['location']),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(eligible ? LucideIcons.check : LucideIcons.x, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(course['prereq'], style: AppText.body.copyWith(fontSize: 13, color: color))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: canAdd
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo only — course registration is not connected.')))
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.lineSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('Add course',
                  style: AppText.button.copyWith(color: canAdd ? Colors.white : AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 13))),
        ],
      );
}
