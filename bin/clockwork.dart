// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clockwork/cli/parsing.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/database/paths.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:intl/intl.dart';

ClockworkDatabase openCliDatabase() {
  final file = databaseFile();
  file.parent.createSync(recursive: true);
  return ClockworkDatabase(NativeDatabase(file));
}

Future<Tag?> findTag(ClockworkDatabase db, String nameOrId) async {
  final tags = await db.tagDao.getAll();
  final asId = int.tryParse(nameOrId);
  for (final tag in tags) {
    if (tag.id == asId || tag.name.toLowerCase() == nameOrId.toLowerCase()) {
      return tag;
    }
  }
  return null;
}

const _autoCreateColors = [
  0xFF64B5F6,
  0xFF81C784,
  0xFFFFB74D,
  0xFFBA68C8,
  0xFF4DD0E1,
  0xFFE57373,
  0xFFFFD54F,
  0xFF90A4AE,
];

/// Finds a tag by name, creating it when missing.
Future<Tag> findOrCreateTag(ClockworkDatabase db, String name) async {
  final existing = await findTag(db, name);
  if (existing != null) return existing;
  final tags = await db.tagDao.getAll();
  final id = await db.tagDao.createTag(
    TagsCompanion.insert(
      name: name,
      color: _autoCreateColors[tags.length % _autoCreateColors.length],
    ),
  );
  print('Created project "$name"');
  final created = await db.tagDao.getAll();
  return created.firstWhere((tag) => tag.id == id);
}

class AddCommand extends Command {
  AddCommand(this.db) {
    argParser
      ..addOption('project',
          abbr: 'p', help: 'Project name or id (created if missing)')
      ..addOption('day',
          abbr: 'd',
          help: 'today, yesterday or YYYY-MM-DD (default: today)')
      ..addOption('comment', abbr: 'c', help: 'Optional comment')
      ..addOption('task', help: 'Optional task id to link');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'add';

  @override
  String get description =>
      'Add worked time to a day.\n'
      'Examples:\n'
      '  clockwork add +2 --project p-name --day today\n'
      '  clockwork add 90m --project p-name --day yesterday -c "fixes"';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('Duration required, e.g. +2, 90m or 1h30m', usage);
    }
    final minutes = parseDurationMinutes(rest.first);
    if (minutes == null) {
      throw UsageException(
          'Invalid duration "${rest.first}", e.g. +2, 90m or 1h30m', usage);
    }

    final day = parseDayOption(argResults!['day'] as String?);
    if (day == null) {
      throw UsageException(
          'Invalid day "${argResults!['day']}", use today, yesterday '
          'or YYYY-MM-DD',
          usage);
    }

    int? tagId;
    final project = argResults!['project'] as String?;
    if (project != null) {
      tagId = (await findOrCreateTag(db, project)).id;
    }

    int? taskId;
    final taskOption = argResults!['task'] as String?;
    if (taskOption != null) {
      taskId = int.tryParse(taskOption);
      if (taskId == null) throw UsageException('Invalid task id', usage);
    }

    final id = await db.timeEntryDao.createEntry(
      TimeEntriesCompanion.insert(
        date: dateKey(day),
        minutes: minutes,
        tagId: Value(tagId),
        taskId: Value(taskId),
        notes: Value(argResults!['comment'] as String?),
      ),
    );
    print(
      'Added time entry #$id: ${formatDuration(Duration(minutes: minutes))} '
      'on ${dateKey(day)}'
      '${project != null ? ' for project "$project"' : ''}',
    );
  }
}

class ListCommand extends Command {
  ListCommand(this.db) {
    argParser.addOption('day',
        abbr: 'd', help: 'today, yesterday or YYYY-MM-DD');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List time entries of a day';

  @override
  Future<void> run() async {
    final day = parseDayOption(argResults!['day'] as String?);
    if (day == null) {
      throw UsageException('Invalid day "${argResults!['day']}"', usage);
    }
    final entries = await db.timeEntryDao.getForDate(dateKey(day));
    if (entries.isEmpty) {
      print('No time entries on ${dateKey(day)}');
      return;
    }
    final tags = {for (final tag in await db.tagDao.getAll()) tag.id: tag};
    var total = Duration.zero;
    for (final entry in entries) {
      final project =
          entry.tagId == null ? '' : '  #${tags[entry.tagId]?.name}';
      final comment = entry.notes == null ? '' : '  ${entry.notes}';
      final duration = Duration(minutes: entry.minutes);
      total += duration;
      print(
        '${entry.id.toString().padLeft(3)}  '
        '${formatDuration(duration).padLeft(8)}$project$comment',
      );
    }
    print('Total: ${formatDuration(total)}');
  }
}

class TaskCommand extends Command {
  TaskCommand(this.db) {
    addSubcommand(TaskAddCommand(db));
    addSubcommand(TaskListCommand(db));
    addSubcommand(TaskDoneCommand(db));
    addSubcommand(TaskRemoveCommand(db));
  }

  final ClockworkDatabase db;

  @override
  String get name => 'task';

  @override
  String get description => 'Manage tasks';
}

class TaskAddCommand extends Command {
  TaskAddCommand(this.db) {
    argParser
      ..addOption('project', abbr: 'p', help: 'Project name or id')
      ..addOption('day',
          abbr: 'd', help: 'today, yesterday or YYYY-MM-DD');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'add';

  @override
  String get description => 'Add a task';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Task title required', usage);
    final title = rest.join(' ');
    int? tagId;
    final project = argResults!['project'] as String?;
    if (project != null) {
      final tag = await findTag(db, project);
      if (tag == null) {
        stderr.writeln('Project "$project" not found');
        exitCode = 1;
        return;
      }
      tagId = tag.id;
    }
    final day = parseDayOption(argResults!['day'] as String?);
    if (day == null) {
      throw UsageException('Invalid day "${argResults!['day']}"', usage);
    }
    final id = await db.taskDao.createTask(
      TasksCompanion.insert(
        title: title,
        date: dateKey(day),
        tagId: Value(tagId),
      ),
    );
    print('Added task #$id "$title" on ${dateKey(day)}');
  }
}

class TaskListCommand extends Command {
  TaskListCommand(this.db) {
    argParser.addOption('day',
        abbr: 'd', help: 'today, yesterday or YYYY-MM-DD');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List tasks';

  @override
  Future<void> run() async {
    final day = parseDayOption(argResults!['day'] as String?);
    if (day == null) {
      throw UsageException('Invalid day "${argResults!['day']}"', usage);
    }
    final tasks = await db.taskDao.getForDate(dateKey(day));
    if (tasks.isEmpty) {
      print('No tasks on ${dateKey(day)}');
      return;
    }
    final tags = {for (final tag in await db.tagDao.getAll()) tag.id: tag};
    for (final task in tasks) {
      final mark = task.done ? '[x]' : '[ ]';
      final project =
          task.tagId == null ? '' : '  #${tags[task.tagId]?.name}';
      print('${task.id.toString().padLeft(3)}  $mark ${task.title}$project');
    }
  }
}

class TaskDoneCommand extends Command {
  TaskDoneCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'done';

  @override
  String get description => 'Mark a task as done';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Task id required', usage);
    final id = int.tryParse(rest.first);
    if (id == null) throw UsageException('Invalid task id', usage);
    await db.taskDao.setDone(id, true);
    print('Marked task #$id as done');
  }
}

class TaskRemoveCommand extends Command {
  TaskRemoveCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'rm';

  @override
  String get description => 'Remove a task';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Task id required', usage);
    final id = int.tryParse(rest.first);
    if (id == null) throw UsageException('Invalid task id', usage);
    await db.taskDao.deleteTask(id);
    print('Removed task #$id');
  }
}

class ProjectCommand extends Command {
  ProjectCommand(this.db) {
    addSubcommand(ProjectAddCommand(db));
    addSubcommand(ProjectListCommand(db));
    addSubcommand(ProjectRemoveCommand(db));
  }

  final ClockworkDatabase db;

  @override
  String get name => 'project';

  @override
  List<String> get aliases => const ['tag'];

  @override
  String get description => 'Manage projects (tags)';
}

class ProjectAddCommand extends Command {
  ProjectAddCommand(this.db) {
    argParser
      ..addOption('parent', abbr: 'P', help: 'Parent project name or id')
      ..addOption('color', abbr: 'c', help: 'Color as RRGGBB hex');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'add';

  @override
  String get description => 'Add a project';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Project name required', usage);
    final name = rest.join(' ');
    int? parentId;
    final parent = argResults!['parent'] as String?;
    if (parent != null) {
      final parentTag = await findTag(db, parent);
      if (parentTag == null) {
        stderr.writeln('Parent project "$parent" not found');
        exitCode = 1;
        return;
      }
      parentId = parentTag.id;
    }
    final colorHex = argResults!['color'] as String?;
    final color = colorHex == null
        ? 0xFF64B5F6
        : int.parse(colorHex, radix: 16) | 0xFF000000;
    final id = await db.tagDao.createTag(
      TagsCompanion.insert(
        name: name,
        color: color,
        parentId: Value(parentId),
      ),
    );
    print('Added project #$id "$name"');
  }
}

class ProjectListCommand extends Command {
  ProjectListCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List projects';

  @override
  Future<void> run() async {
    final tags = await db.tagDao.getAll();
    if (tags.isEmpty) {
      print('No projects');
      return;
    }
    final byId = {for (final tag in tags) tag.id: tag};
    for (final tag in tags) {
      final parent = tag.parentId == null
          ? ''
          : ' (under ${byId[tag.parentId]?.name})';
      print('${tag.id.toString().padLeft(3)}  ${tag.name}$parent');
    }
  }
}

class ProjectRemoveCommand extends Command {
  ProjectRemoveCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'rm';

  @override
  String get description => 'Remove a project';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('Project name or id required', usage);
    }
    final tag = await findTag(db, rest.first);
    if (tag == null) {
      stderr.writeln('Project "${rest.first}" not found');
      exitCode = 1;
      return;
    }
    await db.tagDao.deleteTag(tag.id);
    print('Removed project "${tag.name}"');
  }
}

class TodayCommand extends Command {
  TodayCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'today';

  @override
  String get description => 'Show today overview';

  @override
  Future<void> run() async {
    final key = dateKey(DateTime.now());
    final tasks = await db.taskDao.getForDate(key);
    print('== Tasks ($key) ==');
    if (tasks.isEmpty) print('  (none)');
    for (final task in tasks) {
      print('  ${task.done ? '[x]' : '[ ]'} ${task.title}');
    }
    print('');
    final entries = await db.timeEntryDao.getForDate(key);
    final tags = {for (final tag in await db.tagDao.getAll()) tag.id: tag};
    var total = Duration.zero;
    print('== Time ==');
    if (entries.isEmpty) print('  (none)');
    for (final entry in entries) {
      final project =
          entry.tagId == null ? '' : '  #${tags[entry.tagId]?.name}';
      final duration = Duration(minutes: entry.minutes);
      total += duration;
      print('  ${formatDuration(duration)}$project');
    }
    print('Total: ${formatDuration(total)}');
  }
}

class WeekCommand extends Command {
  WeekCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'week';

  @override
  String get description => 'Show this week summary';

  @override
  Future<void> run() async {
    final monday = startOfWeek(DateTime.now());
    final keys = weekKeys(DateTime.now());
    final perDay = <String, Duration>{};
    final perTag = <int, Duration>{};
    var total = Duration.zero;
    for (final key in keys) {
      for (final entry in await db.timeEntryDao.getForDate(key)) {
        final duration = Duration(minutes: entry.minutes);
        total += duration;
        perDay[key] = (perDay[key] ?? Duration.zero) + duration;
        final tagId = entry.tagId;
        if (tagId != null) {
          perTag[tagId] = (perTag[tagId] ?? Duration.zero) + duration;
        }
      }
    }
    final tags = {for (final tag in await db.tagDao.getAll()) tag.id: tag};

    print(
      '== Week ${DateFormat.MMMd().format(monday)} - '
      '${DateFormat.MMMd().format(monday.add(const Duration(days: 6)))} ==',
    );
    for (var i = 0; i < keys.length; i++) {
      final day = monday.add(Duration(days: i));
      final dayTotal = perDay[keys[i]];
      print(
        '  ${DateFormat.E().format(day)} ${day.day.toString().padLeft(2)}  '
        '${dayTotal == null ? '-' : formatDuration(dayTotal)}',
      );
    }
    print('');
    for (final tagId in perTag.keys) {
      print('  #${tags[tagId]?.name ?? tagId}: '
          '${formatDuration(perTag[tagId]!)}');
    }
    print('Total: ${formatDuration(total)}');
  }
}

Future<void> main(List<String> arguments) async {
  final db = openCliDatabase();
  final runner = CommandRunner<void>(
    'clockwork',
    'Track tasks and worked time from the terminal.\n'
    'Data is stored in ${databaseFile().path}',
  )
    ..addCommand(AddCommand(db))
    ..addCommand(ListCommand(db))
    ..addCommand(TaskCommand(db))
    ..addCommand(ProjectCommand(db))
    ..addCommand(TodayCommand(db))
    ..addCommand(WeekCommand(db));

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  } finally {
    await db.close();
  }
}
