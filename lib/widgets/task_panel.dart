import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../database/dates.dart';
import '../providers/providers.dart';
import 'task_edit_dialog.dart';

class TaskPanel extends ConsumerWidget {
  const TaskPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasks = ref.watch(filteredTasksProvider);
    final tags = ref.watch(tagsProvider).valueOrNull ?? [];
    final entries = ref.watch(weekEntriesProvider).valueOrNull ?? [];
    final key = dateKey(selectedDate);
    final dayEntries = entries.where((e) => dateKey(e.start) == key).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final dayTotal = dayEntries.fold<Duration>(
        Duration.zero, (sum, e) => sum + entryDuration(e.start, e.end));
    final tagById = {for (final t in tags) t.id: t};

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('EEEE d MMMM').format(selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _AddTaskField(dateKey: key),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks for this day'))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => _TaskTile(
                      task: tasks[index],
                      tag: tasks[index].tagId == null
                          ? null
                          : tagById[tasks[index].tagId],
                    ),
                  ),
          ),
          const Divider(),
          Text('Tracked time: ${formatDuration(dayTotal)}',
              style: Theme.of(context).textTheme.titleSmall),
          for (final entry in dayEntries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 5,
                backgroundColor: entry.tagId == null
                    ? Colors.grey
                    : Color(tagById[entry.tagId]?.color ?? 0xFF888888),
              ),
              title: Text(
                entry.notes ?? tagById[entry.tagId]?.name ?? 'Time entry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${DateFormat.Hm().format(entry.start)} - '
                '${DateFormat.Hm().format(entry.end)}',
              ),
              trailing: Text(formatDuration(entryDuration(entry.start, entry.end))),
              onLongPress: () => _confirmDeleteEntry(context, ref, entry),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEntry(
      BuildContext context, WidgetRef ref, TimeEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete time entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(timeEntryDaoProvider).deleteEntry(entry.id);
    }
  }
}

class _AddTaskField extends ConsumerStatefulWidget {
  const _AddTaskField({required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends ConsumerState<_AddTaskField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await ref.read(taskDaoProvider).createTask(
          TasksCompanion.insert(
            title: title,
            date: widget.dateKey,
            tagId: Value(ref.read(tagFilterProvider)),
          ),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'Add a task...',
        prefixIcon: Icon(Icons.add),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, this.tag});

  final Task task;
  final Tag? tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.done,
        onChanged: (value) => ref
            .read(taskDaoProvider)
            .setDone(task.id, value ?? false),
      ),
      title: Text(
        task.title,
        style: task.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          if (tag != null) tag!.name,
          if (task.notes != null && task.notes!.isNotEmpty) task.notes!,
        ].join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: tag == null
          ? null
          : CircleAvatar(radius: 6, backgroundColor: Color(tag!.color)),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}
