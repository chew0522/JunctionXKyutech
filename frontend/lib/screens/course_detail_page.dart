import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/list_card.dart';
import 'submission_portal_page.dart';

const _tabs = ['Dashboard', 'Materials', 'Assignments', 'Quizzes', 'Grades', 'Attendance', 'Calendar'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _shortDate(String iso) {
  final d = DateTime.parse(iso);
  return '${weekdayShort(d)} ${d.day} ${_months[d.month - 1]}';
}

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onBack;

  const CourseDetailPage({super.key, required this.course, required this.onBack});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _api = ApiClient();
  Map<String, dynamic>? _detail;
  DateTime _now = DateTime.now();
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
      final r = await Future.wait([_api.fetchCourseDetail(widget.course['id']), _api.fetchNow()]);
      setState(() {
        _detail = r[0] as Map<String, dynamic>;
        _now = r[1] as DateTime;
      });
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
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.course['code']} ${widget.course['name']}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title.copyWith(fontSize: 19)),
                        Text('${widget.course['instructor']} · ${widget.course['semester']}',
                            style: AppText.metaKey.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TabPill(label: _tabs[i], active: i == _tab, onTap: () => setState(() => _tab = i)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load this course.", style: AppText.body),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final d = _detail;
    if (d == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    final content = switch (_tab) {
      0 => _dashboard(d),
      1 => _materials(d['materials']),
      2 => _assignments(d['assignments']),
      3 => _quizzes(d['quizzes']),
      4 => _grades(d['grades']),
      5 => _attendance(d['attendance']),
      _ => _agenda(d['agenda']),
    };
    return ListView(
      key: ValueKey(_tab),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [content],
    );
  }

  // ---- Dashboard ----

  Widget _dashboard(Map<String, dynamic> d) {
    final pending = (d['assignments'] as List).where((a) => a['submitted'] != true).toList()
      ..sort((a, b) => parseDateTime(a['due_date'], a['due_time']).compareTo(parseDateTime(b['due_date'], b['due_time'])));
    final upcomingQuizzes = d['quizzes']['upcoming'] as List;
    final graded = d['grades']['graded'] as List;
    final att = d['attendance'];

    final nextDue = pending.isEmpty ? null : pending.first;
    final nextQuiz = upcomingQuizzes.isEmpty ? null : upcomingQuizzes.first;
    final latest = graded.isEmpty ? null : graded.first;

    Widget tile(IconData icon, String label, String value, String sub, int goToTab) => Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _tab = goToTab),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(label, style: AppText.metaKey.copyWith(fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Text(value, style: AppText.cardTitle.copyWith(fontSize: 20, color: AppColors.primary)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.metaKey.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        );

    final nextDueValue = nextDue == null ? '—' : dueLabel(parseDateTime(nextDue['due_date'], nextDue['due_time']), _now).text;
    final quizDate = nextQuiz == null ? null : DateTime.parse(nextQuiz['date']);

    final agenda = (d['agenda'] as List).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('THIS COURSE, AT A GLANCE'),
        Row(children: [
          tile(LucideIcons.checkSquare, 'Next due', nextDueValue, nextDue?['title'] ?? 'All caught up', 2),
          const SizedBox(width: 10),
          tile(LucideIcons.clipboardList, 'Next quiz', quizDate == null ? '—' : '${quizDate.day} ${_months[quizDate.month - 1]}',
              nextQuiz?['title'] ?? 'None scheduled', 3),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          tile(LucideIcons.award, 'Latest grade', latest == null ? '—' : '${latest['score']} / ${latest['max']}',
              latest?['title'] ?? 'Nothing graded', 4),
          const SizedBox(width: 10),
          tile(LucideIcons.calendarCheck, 'Attendance', att['rate'] == null ? '—' : '${att['rate']}%',
              '${att['attended']} of ${att['total']} sessions', 5),
        ]),
        const SectionLabel('COMING UP'),
        if (agenda.isEmpty)
          ListCard(rows: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Nothing coming up.', style: AppText.body.copyWith(color: AppColors.textMuted)),
            ),
          ])
        else
          ListCard(rows: [for (final e in agenda) _agendaRow(e, showDetail: false)]),
      ],
    );
  }

  // ---- Materials ----

  Widget _materials(List materials) {
    if (materials.isEmpty) return _empty('No materials posted yet.');
    final weeks = <int>{for (final m in materials) m['week'] as int}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in weeks) ...[
          SectionLabel('WEEK $w'),
          ListCard(rows: [
            for (final m in materials.where((m) => m['week'] == w))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                        switch (m['type']) {
                          'slides' => LucideIcons.presentation,
                          'reading' => LucideIcons.bookOpen,
                          'video' => LucideIcons.video,
                          _ => LucideIcons.file,
                        },
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                          Text('Week ${m['week']}', style: AppText.metaKey.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                    Text((m['type'] as String)[0].toUpperCase() + (m['type'] as String).substring(1),
                        style: AppText.metaKey.copyWith(fontSize: 12)),
                  ],
                ),
              ),
          ]),
        ],
      ],
    );
  }

  // ---- Assignments ----

  Widget _assignments(List assignments) {
    if (assignments.isEmpty) return _empty('No assignments yet.');
    final open = assignments.where((a) => a['submitted'] != true).length;
    final sorted = [...assignments]..sort((a, b) => parseDateTime(a['due_date'], a['due_time'])
        .compareTo(parseDateTime(b['due_date'], b['due_time'])));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('ASSIGNMENTS · $open NOT SUBMITTED'),
        ListCard(rows: [
          for (final a in sorted)
            InkWell(
              onTap: a['submitted'] == true ? null : () => _openSubmission(a),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: a['submitted'] == true ? AppColors.success : null,
                        border: Border.all(color: a['submitted'] == true ? AppColors.success : AppColors.textMuted, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: a['submitted'] == true ? const Icon(LucideIcons.check, size: 12, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a['title'], style: AppText.metaValue.copyWith(fontSize: 14))),
                    const SizedBox(width: 8),
                    _assignmentBadge(a),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _assignmentBadge(Map<String, dynamic> a) {
    if (a['submitted'] == true) {
      final text = a['score'] != null ? 'Graded ${a['score']}/${a['max_score']}' : 'Submitted';
      return _Badge(text: text, fill: AppColors.successFill, color: AppColors.success);
    }
    final due = parseDateTime(a['due_date'], a['due_time']);
    final l = dueLabel(due, _now);
    if (due.isBefore(_now)) return const _Badge(text: 'Overdue', fill: Color(0xFFFBE9E5), color: AppColors.danger);
    return _Badge(
      text: l.text,
      fill: l.isToday ? AppColors.primary : AppColors.primaryTint,
      color: l.isToday ? Colors.white : AppColors.primary,
    );
  }

  void _openSubmission(Map<String, dynamic> a) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => SubmissionPortalPage(
          assignment: a,
          course: widget.course,
          onBack: () => Navigator.of(ctx).pop(),
          onSubmitted: _load,
        ),
      ),
    );
  }

  // ---- Quizzes ----

  Widget _quizzes(Map<String, dynamic> q) {
    final upcoming = q['upcoming'] as List;
    final completed = q['completed'] as List;
    if (upcoming.isEmpty && completed.isEmpty) return _empty('No quizzes or exams scheduled.');

    Widget row(Map<String, dynamic> item, Widget badge, {bool done = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: done ? AppColors.successFill : AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.clipboardList, size: 18, color: done ? AppColors.success : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                    Text('${_shortDate(item['date'])}, ${item['time']} · ${item['mode']} · ${item['duration']} min',
                        style: AppText.metaKey.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badge,
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcoming.isNotEmpty) ...[
          const SectionLabel('UPCOMING'),
          ListCard(rows: [
            for (final item in upcoming)
              row(item, const _Badge(text: 'Upcoming', fill: AppColors.primaryTint, color: AppColors.primary)),
          ]),
        ],
        if (completed.isNotEmpty) ...[
          const SectionLabel('COMPLETED'),
          ListCard(rows: [
            for (final item in completed)
              row(item, _Badge(text: '${item['score']} / ${item['max']}', fill: AppColors.successFill, color: AppColors.success),
                  done: true),
          ]),
        ],
      ],
    );
  }

  // ---- Grades ----

  Widget _grades(Map<String, dynamic> g) {
    final graded = g['graded'] as List;
    final pending = g['pending'] as List;
    Widget row(String title, int weight, String trailing, {bool muted = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.metaValue.copyWith(fontSize: 14)),
                    Text('$weight% of final grade', style: AppText.metaKey.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Text(trailing, style: AppText.metaValue.copyWith(fontSize: 14, color: muted ? AppColors.text : AppColors.text)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            border: Border.all(color: AppColors.primaryLine),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall grade', style: AppText.metaKey.copyWith(fontSize: 13)),
                    Text('Based on graded work so far', style: AppText.metaValue.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              Text(g['overall'] == null ? '—' : '${g['overall']}%',
                  style: AppText.display.copyWith(fontSize: 30)),
            ],
          ),
        ),
        if (graded.isNotEmpty) ...[
          const SectionLabel('GRADED'),
          ListCard(rows: [for (final x in graded) row(x['title'], x['weight'], '${x['score']} / ${x['max']}')]),
        ],
        if (pending.isNotEmpty) ...[
          const SectionLabel('PENDING'),
          ListCard(rows: [for (final x in pending) row(x['title'], x['weight'], x['status'], muted: true)]),
        ],
      ],
    );
  }

  // ---- Attendance ----

  Widget _attendance(Map<String, dynamic> a) {
    final recent = a['recent'] as List;
    Color statusColor(String s) => switch (s) {
          'Present' => AppColors.success,
          'Absent' => AppColors.danger,
          _ => AppColors.textMuted,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            border: Border.all(color: AppColors.primaryLine),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance rate', style: AppText.metaKey.copyWith(fontSize: 13)),
                    Text('${a['attended']} of ${a['total']} sessions', style: AppText.metaValue.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              Text(a['rate'] == null ? '—' : '${a['rate']}%', style: AppText.display.copyWith(fontSize: 30)),
            ],
          ),
        ),
        const SectionLabel('RECENT SESSIONS'),
        ListCard(rows: [
          for (final s in recent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(_shortDate(s['date']), style: AppText.metaValue.copyWith(fontSize: 14))),
                  Text(s['status'],
                      style: AppText.metaValue.copyWith(fontSize: 13, color: statusColor(s['status']))),
                ],
              ),
            ),
        ]),
      ],
    );
  }

  // ---- Calendar (agenda) ----

  Widget _agenda(List agenda) {
    if (agenda.isEmpty) return _empty('Nothing coming up for this course.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('THIS COURSE · AGENDA VIEW'),
        ListCard(rows: [for (final e in agenda) _agendaRow(e)]),
      ],
    );
  }

  Widget _agendaRow(Map<String, dynamic> e, {bool showDetail = true}) {
    final d = DateTime.parse(e['date']);
    final label = isSameDay(d, _now) ? 'Today' : '${weekdayShort(d)} ${d.day}\n${_months[d.month - 1]}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: AppText.metaValue.copyWith(fontSize: 14, color: AppColors.primary)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                if (showDetail) Text(e['detail'], style: AppText.metaKey.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: AppText.body.copyWith(color: AppColors.textMuted)),
      );
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.active, required this.onTap});

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
          child: Text(label,
              style: AppText.button.copyWith(fontSize: 14, color: active ? Colors.white : AppColors.primary)),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color fill;
  final Color color;

  const _Badge({required this.text, required this.fill, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text, style: AppText.button.copyWith(fontSize: 12, color: color)),
    );
  }
}
