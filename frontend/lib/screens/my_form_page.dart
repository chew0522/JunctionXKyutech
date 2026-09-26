import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/async_page.dart';
import '../widgets/list_card.dart';
import '../widgets/page_header.dart';

IconData _formIcon(String? name) => switch (name) {
      'calendar' => LucideIcons.calendarDays,
      'receipt' => LucideIcons.receipt,
      'building' => LucideIcons.building,
      'plane' => LucideIcons.plane,
      _ => LucideIcons.fileText,
    };

class MyFormPage extends StatefulWidget {
  final VoidCallback onBack;

  const MyFormPage({super.key, required this.onBack});

  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final _api = ApiClient();
  ({List forms, List submissions})? _data;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errored = false);
    try {
      final r = await Future.wait([_api.fetchForms(), _api.fetchFormSubmissions()]);
      setState(() => _data = (forms: r[0], submissions: r[1]));
    } catch (_) {
      setState(() => _errored = true);
    }
  }

  Future<void> _open(Map<String, dynamic> form) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => FormFillPage(form: form, onBack: () => Navigator.of(ctx).pop())),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncPage<({List forms, List submissions})>(
      title: 'MyForm',
      onBack: widget.onBack,
      data: _data,
      errored: _errored,
      onRetry: _load,
      builder: (d) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionLabel('AVAILABLE FORMS'),
          ListCard(rows: [
            for (final f in d.forms)
              InkWell(
                onTap: () => _open(f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_formIcon(f['icon']), size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                            Text(f['description'], style: AppText.metaKey.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
          ]),
          if (d.submissions.isNotEmpty) ...[
            const SectionLabel('MY SUBMISSIONS'),
            ListCard(rows: [
              for (final s in d.submissions)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['title'], style: AppText.metaValue.copyWith(fontSize: 14)),
                            Text((s['submitted_at'] as String).substring(0, 10),
                                style: AppText.metaKey.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(s['status'],
                            style: AppText.button.copyWith(fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}

class FormFillPage extends StatefulWidget {
  final Map<String, dynamic> form;
  final VoidCallback onBack;

  const FormFillPage({super.key, required this.form, required this.onBack});

  @override
  State<FormFillPage> createState() => _FormFillPageState();
}

class _FormFillPageState extends State<FormFillPage> {
  final _api = ApiClient();
  final Map<String, dynamic> _values = {};
  bool _sending = false;
  bool _done = false;
  String? _error;

  List get _fields => widget.form['fields'] as List;

  bool get _valid => _fields.every((f) => f['required'] != true || ('${_values[f['key']] ?? ''}').trim().isNotEmpty);

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.submitForm(widget.form['id'], _values);
      setState(() => _done = true);
    } catch (_) {
      setState(() => _error = "Couldn't submit the form. Please try again.");
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _pickDate(String key) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() => _values[key] = '${d.year}-${two(d.month)}-${two(d.day)}');
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppText.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputLine)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputLine)),
      );

  Widget _field(Map<String, dynamic> f) {
    final key = f['key'] as String;
    final label = '${f['label']}${f['required'] == true ? ' *' : ''}';
    switch (f['type']) {
      case 'multiline':
        return TextField(
          minLines: 3,
          maxLines: 5,
          style: AppText.body,
          decoration: _decoration(label),
          onChanged: (v) => setState(() => _values[key] = v),
        );
      case 'number':
        return TextField(
          keyboardType: TextInputType.number,
          style: AppText.body,
          decoration: _decoration(label),
          onChanged: (v) => setState(() => _values[key] = v),
        );
      case 'date':
        return InkWell(
          onTap: () => _pickDate(key),
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _decoration(label).copyWith(suffixIcon: const Icon(LucideIcons.calendar, size: 18)),
            child: Text(_values[key] ?? 'Select a date',
                style: AppText.body.copyWith(color: _values[key] == null ? AppColors.textMuted : AppColors.text)),
          ),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _values[key],
          decoration: _decoration(label),
          style: AppText.body,
          items: [for (final o in f['options']) DropdownMenuItem(value: o as String, child: Text(o))],
          onChanged: (v) => setState(() => _values[key] = v),
        );
      default:
        return TextField(
          style: AppText.body,
          decoration: _decoration(label),
          onChanged: (v) => setState(() => _values[key] = v),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: widget.form['title'], onBack: widget.onBack),
            Expanded(child: _done ? _success() : _formBody()),
          ],
        ),
      ),
    );
  }

  Widget _formBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(widget.form['description'], style: AppText.body.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        for (final f in _fields) ...[
          _field(f as Map<String, dynamic>),
          const SizedBox(height: 14),
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _valid && !_sending ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.lineSoft,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            child: Text(_sending ? 'Submitting…' : 'Submit',
                style: AppText.button.copyWith(color: _valid ? Colors.white : AppColors.textMuted)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppText.metaKey.copyWith(fontSize: 13)),
        ],
      ],
    );
  }

  Widget _success() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Form submitted', style: AppText.title.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text('Status: Pending review', style: AppText.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: widget.onBack, child: const Text('Done')),
        ],
      ),
    );
  }
}
