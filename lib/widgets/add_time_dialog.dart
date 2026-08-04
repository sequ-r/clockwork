import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../database/dates.dart';
import '../providers/providers.dart';

class AddTimeDialog extends ConsumerStatefulWidget {
  const AddTimeDialog({super.key});

  @override
  ConsumerState<AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends ConsumerState<AddTimeDialog> {
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  int? _tagId;
  int? _taskId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = ref.read(selectedDateProvider);
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final roundedMinute = (now.minute / 5).round() * 5;
    var hour = now.hour;
    var minute = roundedMinute;
    if (minute >= 60) {
      minute = 0;
      hour = (hour + 1) % 24;
    }
    _end = TimeOfDay(hour: hour, minute: minute);
    _start = TimeOfDay(hour: (hour + 23) % 24, minute: minute);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _startDateTime =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);

  DateTime get _endDateTime =>
      DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);

  Duration get _duration => _endDateTime.difference(_startDateTime);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_duration <= Duration.zero) return;
    await ref.read(timeEntryDaoProvider).createEntry(
          TimeEntriesCompanion.insert(
            start: _startDateTime,
            end: _endDateTime,
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
    final eligibleTasks =
        tasks.where((t) => _tagId == null || t.tagId == _tagId).toList();

    return AlertDialog(
      title: const Text('Track time'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        final task =
                            tasks.where((t) => t.id == _taskId).firstOrNull;
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
                            value: task.id, child: Text(task.title)),
                    ],
                    onChanged: (value) =>
                        setState(() => _taskId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat.yMMMd().format(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule),
                    label: Text(_start.format(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule),
                    label: Text(_end.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            if (_duration <= Duration.zero)
              Text(
                'End time must be after start time',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Text('Duration: ${formatDuration(_duration)}',
                  style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _duration > Duration.zero ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
