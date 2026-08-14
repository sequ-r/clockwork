import 'package:clockwork/app/tokens.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/tasks/task_edit_dialog.dart';
import 'package:clockwork/features/today/today_view_model.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Today pane: welcome header, task list with hours per task, and the
/// time entries logged on the selected day.
class TodayScreen extends StatefulWidget {
  /// Creates the today pane.
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = ClockworkScope.of(context);
    _viewModel ??= TodayViewModel(
      taskRepository: deps.taskRepository,
      timeEntryRepository: deps.timeEntryRepository,
      tagRepository: deps.tagRepository,
      appViewModel: deps.appViewModel,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(kSpacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WelcomeHeader(viewModel: viewModel),
              const SizedBox(height: kSpacingLg),
              _AddTaskField(viewModel: viewModel),
              const SizedBox(height: kSpacingMd),
              Expanded(child: _TaskList(viewModel: viewModel)),
              const Divider(),
              _LoggedTimeSection(viewModel: viewModel),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.viewModel});

  final TodayViewModel viewModel;

  String _greeting(AppLocalizations l10n, DateTime time) {
    return switch (time.hour) {
      < 12 => l10n.todayGreetingMorning,
      < 18 => l10n.todayGreetingAfternoon,
      _ => l10n.todayGreetingEvening,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = viewModel.selectedDate;
    final total = viewModel.selectedDateTotal;
    final overLimit = isOverLimit(total);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting(l10n, selectedDate)}!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: kSpacingXs),
        Text(
          DateFormat('EEEE, d MMMM').format(selectedDate),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: kSpacingSm),
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
              const SizedBox(width: kSpacingSm),
              Tooltip(
                message: l10n.overLimitTooltip(workingHoursLimit.inHours),
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

class _AddTaskField extends StatefulWidget {
  const _AddTaskField({required this.viewModel});

  final TodayViewModel viewModel;

  @override
  State<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<_AddTaskField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await widget.viewModel.addTask(title);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: l10n.todayAddTaskPlaceholder,
        prefixIcon: const Icon(Icons.add),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.viewModel});

  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tasks = viewModel.filteredTasks;
    final l10n = AppLocalizations.of(context)!;

    if (tasks.isEmpty) {
      return Center(child: Text(l10n.todayNoTasks));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) =>
          _TaskTile(task: tasks[index], viewModel: viewModel),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.viewModel});

  final Task task;
  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tags = viewModel.tags;
    final tag = task.tagId == null
        ? null
        : tags.where((t) => t.id == task.tagId).firstOrNull;
    final hours = viewModel.taskHours[task.id];
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.done,
        onChanged: (value) => viewModel.setTaskDone(task.id, value ?? false),
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
            const SizedBox(width: kSpacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(kRadiusMedium),
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

class _LoggedTimeSection extends StatelessWidget {
  const _LoggedTimeSection({required this.viewModel});

  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.entries;
    final tags = viewModel.tags;
    final l10n = AppLocalizations.of(context)!;

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.todayLoggedTimeHeader,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _EntryTile(
                entry: entry,
                tag: entry.tagId == null
                    ? null
                    : tags.where((t) => t.id == entry.tagId).firstOrNull,
                viewModel: viewModel,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, this.tag, required this.viewModel});

  final TimeEntry entry;
  final Tag? tag;
  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 5,
        backgroundColor: tag == null ? Colors.grey : Color(tag!.color),
      ),
      title: Text(
        entry.notes ?? tag?.name ?? l10n.defaultTimeEntryTitle,
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
            tooltip: l10n.deleteEntryTooltip,
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => viewModel.deleteEntry(entry.id),
          ),
        ],
      ),
    );
  }
}
