import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Edit dialog for a single task: title, tag, date and notes.
class TaskEditDialog extends StatefulWidget {
  /// Opens the dialog for [task].
  const TaskEditDialog({super.key, required this.task});

  /// The task being edited.
  final Task task;

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late String _dateKey;
  int? _tagId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes ?? '');
    _dateKey = widget.task.date;
    _tagId = widget.task.tagId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFromKey(_dateKey),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateKey = dateKey(picked));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final deps = ClockworkScope.of(context);
    await deps.taskRepository.updateTask(
      widget.task.copyWith(
        title: title,
        date: _dateKey,
        tagId: Value(_tagId),
        notes: Value(
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final deps = ClockworkScope.of(context);
    await deps.taskRepository.deleteTask(widget.task.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Tag>>(
      stream: deps.tagRepository.watchAll(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const [];

        return AlertDialog(
          title: Text(l10n.editTaskTitle),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.taskTitleLabel),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _tagId,
                        decoration: InputDecoration(labelText: l10n.tagLabel),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.noneOption),
                          ),
                          for (final tag in tags)
                            DropdownMenuItem(
                              value: tag.id,
                              child: Text(tag.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _tagId = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat.yMMMd().format(dateFromKey(_dateKey)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.taskNotesLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: _delete, child: Text(l10n.dialogDelete)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(onPressed: _save, child: Text(l10n.dialogSave)),
          ],
        );
      },
    );
  }
}
