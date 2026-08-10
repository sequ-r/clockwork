import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import '../../providers/providers.dart';

/// Main "+ button" workflow: choose hours to add to the day, attach an
/// optional comment and tag, then confirm.
class AddTimeDialog extends ConsumerStatefulWidget {
  const AddTimeDialog({super.key, this.initialTaskId});

  final int? initialTaskId;

  @override
  ConsumerState<AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends ConsumerState<AddTimeDialog> {
  static const _quickPicks = [15, 30, 60, 120, 240];

  late final TextEditingController _hoursController;
  late final TextEditingController _notesController;
  late DateTime _date;
  int? _tagId;
  int? _taskId;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '1');
    _notesController = TextEditingController();
    _date = ref.read(selectedDateProvider);
    _taskId = widget.initialTaskId;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return null;
    return (hours * 60).round();
  }

  void _setHours(double hours) {
    final rounded = (hours * 100).round() / 100;
    _hoursController.text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    setState(() {});
  }

  void _step(double delta) {
    final current = double.tryParse(_hoursController.text.trim()) ?? 0;
    final next = (current + delta).clamp(0.25, 24.0);
    _setHours(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    final minutes = _minutes;
    if (minutes == null) return;
    await ref
        .read(timeEntryDaoProvider)
        .createEntry(
          TimeEntriesCompanion.insert(
            date: dateKey(_date),
            minutes: minutes,
            tagId: Value(_tagId),
            taskId: Value(_taskId),
            notes: Value(
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider).valueOrNull ?? [];
    final tasks =
        ref.watch(tasksForDateProvider(dateKey(_date))).valueOrNull ?? [];
    final eligibleTasks = tasks
        .where((t) => _tagId == null || t.tagId == _tagId)
        .toList();

    return AlertDialog(
      title: Text('Add time on ${DateFormat.MMMd().format(_date)}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hours', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _step(-0.5),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'h',
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => _step(0.5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final pick in _quickPicks)
                  ChoiceChip(
                    label: Text(pick < 60 ? '${pick}m' : '${pick ~/ 60}h'),
                    selected: _minutes == pick,
                    onSelected: (_) => _setHours(pick / 60),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _tagId,
                    decoration: const InputDecoration(labelText: 'Tag'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      for (final tag in tags)
                        DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                    ],
                    onChanged: (value) => setState(() {
                      _tagId = value;
                      if (_taskId != null) {
                        final task = tasks
                            .where((t) => t.id == _taskId)
                            .firstOrNull;
                        if (task == null ||
                            (value != null && task.tagId != value)) {
                          _taskId = null;
                        }
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _taskId,
                    decoration: const InputDecoration(labelText: 'Task'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      for (final task in eligibleTasks)
                        DropdownMenuItem(
                          value: task.id,
                          child: Text(task.title),
                        ),
                    ],
                    onChanged: (value) => setState(() => _taskId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat.yMMMd().format(_date)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _minutes != null ? _confirm : null,
          icon: const Icon(Icons.check),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
