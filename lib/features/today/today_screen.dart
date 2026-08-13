import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import '../../core/providers/database.dart';
import '../../core/providers/tasks.dart';
import '../../core/providers/time_entries.dart';
import '../../core/providers/ui_state.dart';
import '../tasks/task_edit_dialog.dart';

/// Today pane: welcome header, task list with hours per task, and the
/// time entries logged on the selected day.
class TodayScreen extends ConsumerWidget {
  /// Creates the today pane.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeHeader(),
          SizedBox(height: 16),
          _AddTaskField(),
          SizedBox(height: 12),
          Expanded(child: _TaskList()),
          Divider(),
          _LoggedTimeSection(),
        ],
      ),
    );
  }
}

String _greeting(DateTime time) {
  return switch (time.hour) {
    < 12 => 'Good morning',
    < 18 => 'Good afternoon',
    _ => 'Good evening',
  };
}

class _WelcomeHeader extends ConsumerWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final total = ref.watch(selectedDateTotalProvider);
    final overLimit = isOverLimit(total);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting(selectedDate)}!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM').format(selectedDate),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Tracked: ${formatDuration(total)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (overLimit) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Over the ${workingHoursLimit.inHours}h working limit',
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AddTaskField extends ConsumerStatefulWidget {
  const _AddTaskField();

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
    final day = dateKey(ref.read(selectedDateProvider));
    await ref
        .read(taskDaoProvider)
        .createTask(
          TasksCompanion.insert(
            title: title,
            date: day,
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

class _TaskList extends ConsumerWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredTasksProvider);

    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks for this day'));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).value ?? [];
    final tag = task.tagId == null
        ? null
        : tags.where((t) => t.id == task.tagId).firstOrNull;
    final hours = ref.watch(taskHoursProvider).value?[task.id];
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.done,
        onChanged: (value) =>
            ref.read(taskDaoProvider).setDone(task.id, value ?? false),
      ),
      title: Text(
        task.title,
        style: task.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: tag == null
          ? null
          : Text(tag.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag != null)
            CircleAvatar(radius: 5, backgroundColor: Color(tag.color)),
          if (hours != null && hours > Duration.zero) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatDuration(hours),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ],
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}

class _LoggedTimeSection extends ConsumerWidget {
  const _LoggedTimeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesForSelectedDateProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? [];

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Logged time', style: Theme.of(context).textTheme.titleSmall),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final entry in entries)
                _EntryTile(
                  entry: entry,
                  tag: entry.tagId == null
                      ? null
                      : tags.where((t) => t.id == entry.tagId).firstOrNull,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, this.tag});

  final TimeEntry entry;
  final Tag? tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 5,
        backgroundColor: tag == null ? Colors.grey : Color(tag!.color),
      ),
      title: Text(
        entry.notes ?? tag?.name ?? 'Time entry',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: tag != null && entry.notes != null
          ? Text(tag!.name, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatDuration(Duration(minutes: entry.minutes))),
          IconButton(
            tooltip: 'Delete entry',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () =>
                ref.read(timeEntryDaoProvider).deleteEntry(entry.id),
          ),
        ],
      ),
    );
  }
}
