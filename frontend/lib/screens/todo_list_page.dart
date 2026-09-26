import 'package:flutter/material.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';
import '../widgets/todo_row.dart';
import 'submission_portal_page.dart';

enum _DateFilter { all, next7, next30 }

enum _StatusFilter { all, overdue, upcoming }

class TodoListPage extends StatefulWidget {
  final VoidCallback onBack;

  const TodoListPage({super.key, required this.onBack});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _api = ApiClient();

  bool _loading = true;
  bool _errored = false;
  DateTime _now = DateTime.now();
  List<dynamic> _assignments = [];
  List<dynamic> _courses = [];

  _DateFilter _dateFilter = _DateFilter.all;
  _StatusFilter _statusFilter = _StatusFilter.all;
  String? _subjectFilter; // course_id, null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errored = false;
    });
    try {
      final results = await Future.wait([
        _api.fetchNow(),
        _api.fetchAssignments(pendingOnly: true),
        _api.fetchCourses(),
      ]);
      setState(() {
        _now = results[0] as DateTime;
        _assignments = results[1] as List;
        _courses = results[2] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errored = true;
      });
    }
  }

  Map<String, dynamic>? _courseById(String id) {
    for (final c in _courses) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  List<dynamic> get _filtered {
    return _assignments.where((a) {
      final due = parseDateTime(a['due_date'], a['due_time']);
      final overdue = due.isBefore(_now);

      if (_subjectFilter != null && a['course_id'] != _subjectFilter) return false;

      switch (_statusFilter) {
        case _StatusFilter.overdue:
          if (!overdue) return false;
        case _StatusFilter.upcoming:
          if (overdue) return false;
        case _StatusFilter.all:
          break;
      }

      switch (_dateFilter) {
        case _DateFilter.next7:
          if (due.difference(_now).inDays > 7 || overdue) return false;
        case _DateFilter.next30:
          if (due.difference(_now).inDays > 30 || overdue) return false;
        case _DateFilter.all:
          break;
      }

      return true;
    }).toList()
      ..sort((a, b) => parseDateTime(a['due_date'], a['due_time'])
          .compareTo(parseDateTime(b['due_date'], b['due_time'])));
  }

  void _openSubmission(Map<String, dynamic> assignment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubmissionPortalPage(
          assignment: assignment,
          course: _courseById(assignment['course_id']),
          onBack: () => Navigator.of(context).pop(),
          onSubmitted: () => setState(() {
            _assignments.removeWhere((a) => a['id'] == assignment['id']);
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'To-Do List', onBack: widget.onBack),
            Expanded(
              child: _errored
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Couldn't load your to-dos.", style: AppText.body),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('Try again')),
                        ],
                      ),
                    )
                  : (_loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _content()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final items = _filtered;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SectionLabel('DUE WITHIN'),
        _filterChips(
          {
            _DateFilter.all: 'All time',
            _DateFilter.next7: 'Next 7 days',
            _DateFilter.next30: 'Next 30 days',
          },
          _dateFilter,
          (v) => setState(() => _dateFilter = v),
        ),
        const SectionLabel('STATUS'),
        _filterChips(
          {
            _StatusFilter.all: 'All',
            _StatusFilter.overdue: 'Overdue',
            _StatusFilter.upcoming: 'Upcoming',
          },
          _statusFilter,
          (v) => setState(() => _statusFilter = v),
        ),
        const SectionLabel('SUBJECT'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _subjectChip(null, 'All'),
            for (final c in _courses) _subjectChip(c['id'], c['code']),
          ],
        ),
        const SizedBox(height: 20),
        Text('${items.length} assignment${items.length == 1 ? '' : 's'}',
            style: AppText.label.copyWith(color: AppColors.textMuted, letterSpacing: 0.7)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          ListCard(rows: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Nothing matches these filters.',
                  style: AppText.body.copyWith(color: AppColors.textMuted)),
            ),
          ])
        else
          ListCard(
            rows: items.map((a) {
              final due = parseDateTime(a['due_date'], a['due_time']);
              final overdue = due.isBefore(_now);
              final label = overdue ? 'Overdue · ${dueLabel(due, _now).text}' : dueLabel(due, _now).text;
              final course = _courseById(a['course_id']);
              final courseLabel = course != null ? '${course['code']} ${course['name']}' : '';
              return TodoRow(
                title: a['title'],
                courseLabel: courseLabel,
                dueText: label,
                isUrgent: overdue || dueLabel(due, _now).isToday,
                onTap: () => _openSubmission(a),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _filterChips<T>(Map<T, String> options, T active, void Function(T) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isActive = e.key == active;
        return _Chip(label: e.value, active: isActive, onTap: () => onSelect(e.key));
      }).toList(),
    );
  }

  Widget _subjectChip(String? courseId, String label) {
    final isActive = _subjectFilter == courseId;
    return _Chip(label: label, active: isActive, onTap: () => setState(() => _subjectFilter = courseId));
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: active ? AppColors.primary : AppColors.primaryLine),
          ),
          child: Text(
            label,
            style: AppText.chip.copyWith(color: active ? Colors.white : AppColors.primary),
          ),
        ),
      ),
    );
  }
}
