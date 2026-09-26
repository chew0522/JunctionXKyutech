import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../date_utils.dart';
import '../theme.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';

class SubmissionPortalPage extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final Map<String, dynamic>? course;
  final VoidCallback onBack;
  final VoidCallback onSubmitted;

  const SubmissionPortalPage({
    super.key,
    required this.assignment,
    required this.course,
    required this.onBack,
    required this.onSubmitted,
  });

  @override
  State<SubmissionPortalPage> createState() => _SubmissionPortalPageState();
}

class _SubmissionPortalPageState extends State<SubmissionPortalPage> {
  final _api = ApiClient();
  DateTime _now = DateTime.now();
  String? _attachedFileName;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api.fetchNow().then((now) => setState(() => _now = now)).catchError((_) {});
  }

  void _attachMockFile() {
    // No real file picker plugin for a 24h prototype — this simulates choosing a file
    // closely enough to demo the flow without adding platform permissions/dependencies.
    final title = widget.assignment['title'] as String;
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    setState(() => _attachedFileName = '$slug.pdf');
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await _api.submitAssignment(widget.assignment['id']);
    setState(() => _submitting = false);

    if (result['success'] == true) {
      setState(() => _submitted = true);
      widget.onSubmitted();
    } else {
      setState(() => _error = result['message'] ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = parseDateTime(widget.assignment['due_date'], widget.assignment['due_time']);
    final label = dueLabel(due, _now);
    final courseLabel =
        widget.course != null ? '${widget.course!['code']} ${widget.course!['name']}' : '';
    final description = widget.assignment['description'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: 'Submission Portal', onBack: widget.onBack),
            Expanded(
              child: _submitted ? _successView() : _formView(due, label, courseLabel, description),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView(DateTime due, DueLabel label, String courseLabel, String? description) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SectionLabel('ASSIGNMENT'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.assignment['title'], style: AppText.cardTitle),
              const SizedBox(height: 4),
              Text(courseLabel, style: AppText.metaKey.copyWith(fontSize: 13)),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(description, style: AppText.body.copyWith(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.clock,
                      size: 14, color: label.isToday ? AppColors.primary : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Due ${label.text}',
                    style: AppText.metaValue.copyWith(
                      fontSize: 13,
                      color: label.isToday ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('YOUR FILE'),
        if (_attachedFileName == null)
          InkWell(
            onTap: _attachMockFile,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.inputLine, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.upload, size: 22, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text('Tap to attach a file', style: AppText.metaValue.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('PDF, DOC, or ZIP', style: AppText.metaKey.copyWith(fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_attachedFileName!, style: AppText.metaValue.copyWith(fontSize: 14)),
                ),
                InkWell(
                  onTap: () => setState(() => _attachedFileName = null),
                  child: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppText.body.copyWith(color: AppColors.danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: (_attachedFileName == null || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Text(
              _submitting ? 'Submitting…' : 'Submit assignment',
              style: AppText.button.copyWith(color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "You can't undo this once submitted.",
            textAlign: TextAlign.center,
            style: AppText.metaKey.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _successView() {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.successFill, shape: BoxShape.circle),
              child: const Icon(LucideIcons.check, size: 30, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text('Assignment submitted', style: AppText.title),
            const SizedBox(height: 6),
            Text(
              '${widget.assignment['title']} — Today, $hh:$mm',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: Text('Done', style: AppText.button.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
