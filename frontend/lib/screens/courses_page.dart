import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/course_row.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';
import '../widgets/todo_row.dart';
import 'course_detail_page.dart';
import 'submission_portal_page.dart';

class CoursesPage extends StatefulWidget {
  final void Function(AppTab) onNavigate;
  final VoidCallback onOpenTodoListPage;

  const CoursesPage({
    super.key,
    required this.onNavigate,
    required this.onOpenTodoListPage,
  });

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _api = ApiClient();

  bool _loading = true;
  bool _errored = false;
  DateTime _now = DateTime.now();
  List<dynamic> _assignments = [];
  List<dynamic> _courses = [];

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
        _assignments = (results[1] as List)
          ..sort((a, b) => parseDateTime(a['due_date'], a['due_time'])
              .compareTo(parseDateTime(b['due_date'], b['due_time'])));
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

  int _dueCountFor(String courseId) =>
      _assignments.where((a) => a['course_id'] == courseId).length;

  void _openCourse(Map<String, dynamic> course) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => CourseDetailPage(course: course, onBack: () => Navigator.of(ctx).pop())))
        .then((_) => _load());
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
            PageHeader(title: 'Courses', onBack: () => widget.onNavigate(AppTab.home)),
            Expanded(
              child: _errored
                  ? _ErrorState(onRetry: _load)
                  : (_loading ? _loadingSkeleton() : _content()),
            ),
            FloatingBottomBar(active: AppTab.courses, onTap: widget.onNavigate),
          ],
        ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SectionLabel('TO-DOS'),
        ListCard(rows: List.generate(3, (_) => _skeletonRow())),
        const SectionLabel('MY COURSES'),
        ListCard(rows: List.generate(3, (_) => _skeletonRow())),
      ],
    );
  }

  Widget _skeletonRow() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Container(height: 12, width: 160, color: AppColors.lineSoft),
    );
  }

  Widget _content() {
    final allSubmitted = _assignments.isEmpty;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SectionLabel(
            allSubmitted ? 'TO-DOS · ALL SUBMITTED' : 'TO-DOS · ${_assignments.length} NOT SUBMITTED',
            onTap: widget.onOpenTodoListPage,
          ),
          if (allSubmitted)
            ListCard(rows: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text("You're all caught up.", style: AppText.body.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ])
          else
            ListCard(
              rows: _assignments.map((a) {
                final due = parseDateTime(a['due_date'], a['due_time']);
                final label = dueLabel(due, _now);
                final course = _courseById(a['course_id']);
                final courseLabel = course != null ? '${course['code']} ${course['name']}' : '';
                return TodoRow(
                  title: a['title'],
                  courseLabel: courseLabel,
                  dueText: label.text,
                  isUrgent: label.isToday,
                  onTap: () => _openSubmission(a),
                );
              }).toList(),
            ),
          const SectionLabel('MY COURSES'),
          ListCard(
            rows: _courses.map((c) {
              return CourseRow(
                codeAndName: '${c['code']} ${c['name']}',
                instructor: c['instructor'],
                dueCount: _dueCountFor(c['id']),
                onTap: () => _openCourse(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load your courses.", style: AppText.body),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
