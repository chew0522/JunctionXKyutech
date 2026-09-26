import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/list_card.dart';
import 'my_finance_page.dart';
import 'my_form_page.dart';
import 'my_register_page.dart';
import 'scan_pay_page.dart';
import 'timetable_page.dart';

const _sections = [
  'Personal Details',
  'Address',
  'Next of Kin',
  'Academic Qualification',
  'Study Information',
  'Academic Advisor',
  'Feedback',
  'Emergency Contact',
];

class ProfilePage extends StatefulWidget {
  final void Function(AppTab) onNavigate;

  const ProfilePage({super.key, required this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiClient();
  Map<String, dynamic>? _profile;
  bool _errored = false;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final p = await _api.fetchProfile();
      setState(() => _profile = p);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(child: Text('Profile', style: AppText.title.copyWith(fontSize: 24))),
                  _menuButton(),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _SectionPill(
                  label: _sections[i],
                  active: i == _section,
                  onTap: () => setState(() => _section = i),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
            FloatingBottomBar(active: AppTab.profile, onTap: widget.onNavigate),
          ],
        ),
      ),
    );
  }

  void _push(Widget Function(VoidCallback onBack) build) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => build(() => Navigator.of(ctx).pop())));
  }

  Widget _menuButton() {
    return GestureDetector(
      onTap: _openMenu,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Menu', style: AppText.button.copyWith(fontSize: 14)),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.text),
          ],
        ),
      ),
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        void go(Widget Function(VoidCallback) build) {
          Navigator.of(sheetContext).pop();
          _push(build);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu', style: AppText.title.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                _MenuRow(icon: LucideIcons.user, label: 'MyProfile', onTap: () => Navigator.of(sheetContext).pop()),
                _MenuRow(
                  icon: LucideIcons.clipboardList,
                  label: 'MyRegister',
                  onTap: () => go((back) => MyRegisterPage(onBack: back)),
                ),
                _MenuRow(
                  icon: LucideIcons.calendarDays,
                  label: 'MySchedule',
                  onTap: () => go((back) => TimetablePage(onBack: back)),
                ),
                _MenuRow(
                  icon: LucideIcons.creditCard,
                  label: 'MyFinance',
                  onTap: () => go((back) => MyFinancePage(onBack: back)),
                ),
                _MenuRow(
                  icon: LucideIcons.fileText,
                  label: 'MyForm',
                  onTap: () => go((back) => MyFormPage(onBack: back)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_errored) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load your profile.", style: AppText.body),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final p = _profile;
    if (p == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final Widget content = switch (_section) {
      0 => _personal(p['personal']),
      1 => _address(p['address']),
      2 => _people(p['next_of_kin'], (k) => [
            ['Relationship', k['relationship']],
            ['Phone', k['phone']],
            ['Email', k['email']],
            ['Occupation', k['occupation']],
          ]),
      3 => _qualifications(p['academic_qualification']),
      4 => _study(p['study_information']),
      5 => _advisor(p['advisor']),
      6 => _FeedbackForm(api: _api),
      _ => _people(p['emergency'], (k) => [
            ['Relationship', k['relationship']],
            ['Phone', k['phone']],
            ['Priority', '${k['priority']}'],
          ]),
    };

    return ListView(
      key: ValueKey(_section),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [content, const _MockNote()],
    );
  }

  Widget _personal(Map<String, dynamic> d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text('A', style: AppText.title.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'], style: AppText.cardTitle.copyWith(fontSize: 18)),
                        Text(d['faculty'], style: AppText.metaKey.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.lineSoft),
              _grid([
                ['Matric No.', d['matric']],
                ['Status', d['status']],
                ['Programme', d['programme']],
                ['Semester Session', d['semester']],
                ['Mode of Study', d['mode']],
                ['Classification', d['classification']],
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ScanPayPage(onBack: () => Navigator.of(ctx).pop(), initialTab: 2),
                    ),
                  ),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: Text('Show ID card', style: AppText.button.copyWith(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryLine),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionLabel("STUDENT'S BACKGROUND"),
        ListCard(rows: [for (final r in d['background']) _kvRow(r[0], r[1])]),
        const SectionLabel('SPONSORSHIP'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            border: Border.all(color: AppColors.primaryLine),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d['sponsorship']['name'], style: AppText.metaValue.copyWith(fontSize: 15)),
              Text('Type: ${d['sponsorship']['type']}', style: AppText.metaKey.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _address(Map<String, dynamic> d) {
    Widget block(String label, List lines) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final l in lines) Text(l, style: AppText.body.copyWith(height: 24 / 15))],
              ),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block('PERMANENT ADDRESS', d['permanent']),
        block('CORRESPONDENCE ADDRESS', d['correspondence']),
        const SectionLabel('CONTACT'),
        ListCard(rows: [for (final r in d['contact']) _kvRow(r[0], r[1])]),
      ],
    );
  }

  Widget _people(List people, List<List<dynamic>> Function(Map<String, dynamic>) rows) {
    return Column(
      children: [
        for (final k in people) ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k['name'], style: AppText.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                _grid(rows(k)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _qualifications(List items) {
    return Column(
      children: [
        for (final q in items) ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['level'], style: AppText.cardTitle.copyWith(fontSize: 16)),
                Text(q['institution'], style: AppText.metaKey.copyWith(fontSize: 13)),
                const SizedBox(height: 10),
                _grid([
                  ['Year', q['year']],
                  ['Result', q['result']],
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _study(Map<String, dynamic> d) {
    final done = d['credits_completed'] as int;
    final total = d['credits_required'] as int;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Credit progress', style: AppText.metaKey.copyWith(fontSize: 12)),
              const SizedBox(height: 4),
              Text('$done / $total credits', style: AppText.cardTitle.copyWith(fontSize: 20, color: AppColors.primary)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: done / total,
                  minHeight: 8,
                  backgroundColor: AppColors.lineSoft,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SectionLabel('DETAILS'),
        ListCard(rows: [for (final r in d['info']) _kvRow(r[0], r[1])]),
      ],
    );
  }

  Widget _advisor(Map<String, dynamic> d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                child: const Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'], style: AppText.cardTitle.copyWith(fontSize: 16)),
                    Text('${d['title']} · ${d['department']}', style: AppText.metaKey.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lineSoft),
          _grid([
            ['Email', d['email']],
            ['Office', d['office']],
            ['Office hours', d['hours']],
            ['Next meeting', d['next_meeting']],
          ]),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );

  Widget _grid(List<List<dynamic>> pairs) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final p in pairs)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p[0], style: AppText.metaKey.copyWith(fontSize: 12)),
                    Text('${p[1]}', style: AppText.metaValue.copyWith(fontSize: 14)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(k, style: AppText.metaKey.copyWith(fontSize: 14))),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: AppText.metaValue.copyWith(fontSize: 14))),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.metaValue.copyWith(fontSize: 16))),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SectionPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.button.copyWith(fontSize: 14, color: active ? Colors.white : AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _MockNote extends StatelessWidget {
  const _MockNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.info, size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Fictional demo data only.', style: AppText.metaKey.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  final ApiClient api;

  const _FeedbackForm({required this.api});

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  static const _categories = ['Academic', 'Facilities', 'Campus services', 'This app'];
  final _controller = TextEditingController();
  String _category = _categories.first;
  bool _sending = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _status = null;
    });
    try {
      await widget.api.submitFeedback(_category, text);
      _controller.clear();
      setState(() => _status = 'Thanks, your feedback has been sent.');
    } catch (_) {
      setState(() => _status = "Couldn't send feedback. Please try again.");
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send us feedback', style: AppText.cardTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  label: Text(c),
                  selected: c == _category,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primaryTint,
                  side: BorderSide.none,
                  showCheckmark: false,
                  labelStyle: AppText.button.copyWith(
                    fontSize: 13,
                    color: c == _category ? Colors.white : AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: 'Tell us what could be better…',
              hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.inputLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.inputLine),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text(_sending ? 'Sending…' : 'Submit feedback',
                  style: AppText.button.copyWith(color: Colors.white)),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: AppText.metaKey.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
