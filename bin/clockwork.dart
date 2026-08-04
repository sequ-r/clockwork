// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/command_runner.dart';
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

DateTime parseDateOption(String? value) {
  if (value == null) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  return dateFromKey(value);
}

TimeOfDayish parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    throw UsageException('Invalid time "$value", expected HH:MM', '');
  }
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    throw UsageException('Invalid time "$value", expected HH:MM', '');
  }
  return TimeOfDayish(h, m);
}

class TimeOfDayish {
  TimeOfDayish(this.hour, this.minute);
  final int hour;
  final int minute;
}

Duration parseDuration(String value) {
  final match = RegExp(r'^(?:(\d+)h)?\s*(?:(\d+)m)?$').firstMatch(value);
  if (match == null || (match[1] == null && match[2] == null)) {
    throw UsageException('Invalid duration "$value", expected e.g. 1h30m', '');
  }
  final h = int.parse(match[1] ?? '0');
  final m = int.parse(match[2] ?? '0');
  return Duration(hours: h, minutes: m);
}

class TagCommand extends Command {
  TagCommand(this.db) {
    addSubcommand(TagAddCommand(db));
    addSubcommand(TagListCommand(db));
    addSubcommand(TagRemoveCommand(db));
  }

  final ClockworkDatabase db;

  @override
  String get name => 'tag';

  @override
  String get description => 'Manage tags (projects)';
}

class TagAddCommand extends Command {
  TagAddCommand(this.db) {
    argParser
      ..addOption('parent', abbr: 'p', help: 'Parent tag name or id')
      ..addOption('color', abbr: 'c', help: 'Color as RRGGBB hex');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'add';

  @override
  String get description => 'Add a tag';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('Tag name required', usage);
    }
    final name = rest.join(' ');
    int? parentId;
    final parent = argResults!['parent'] as String?;
    if (parent != null) {
      final parentTag = await findTag(db, parent);
      if (parentTag == null) {
        stderr.writeln('Parent tag "$parent" not found');
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
    print('Added tag #$id "$name"');
  }
}

class TagListCommand extends Command {
  TagListCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List tags';

  @override
  Future<void> run() async {
    final tags = await db.tagDao.getAll();
    if (tags.isEmpty) {
      print('No tags');
      return;
    }
    final byId = {for (final t in tags) t.id: t};
    for (final tag in tags) {
      final parent =
          tag.parentId == null ? '' : ' (under ${byId[tag.parentId]?.name})';
      print('${tag.id.toString().padLeft(3)}  ${tag.name}$parent');
    }
  }
}

class TagRemoveCommand extends Command {
  TagRemoveCommand(this.db);

  final ClockworkDatabase db;

  @override
  String get name => 'rm';

  @override
  String get description => 'Remove a tag';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Tag name or id required', usage);
    final tag = await findTag(db, rest.first);
    if (tag == null) {
      stderr.writeln('Tag "${rest.first}" not found');
      exitCode = 1;
      return;
    }
    await db.tagDao.deleteTag(tag.id);
    print('Removed tag "${tag.name}"');
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
      ..addOption('tag', abbr: 't', help: 'Tag name or id')
      ..addOption('date', abbr: 'd', help: 'Date (YYYY-MM-DD)');
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
    final tagOption = argResults!['tag'] as String?;
    if (tagOption != null) {
      final tag = await findTag(db, tagOption);
      if (tag == null) {
        stderr.writeln('Tag "$tagOption" not found');
        exitCode = 1;
        return;
      }
      tagId = tag.id;
    }
    final date = parseDateOption(argResults!['date'] as String?);
    final id = await db.taskDao.createTask(
      TasksCompanion.insert(
        title: title,
        date: dateKey(date),
        tagId: Value(tagId),
      ),
    );
    print('Added task #$id "$title" on ${dateKey(date)}');
  }
}

class TaskListCommand extends Command {
  TaskListCommand(this.db) {
    argParser.addOption('date', abbr: 'd', help: 'Date (YYYY-MM-DD)');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List tasks';

  @override
  Future<void> run() async {
    final date = parseDateOption(argResults!['date'] as String?);
    final tasks = await db.taskDao.getForDate(dateKey(date));
    if (tasks.isEmpty) {
      print('No tasks on ${dateKey(date)}');
      return;
    }
    final tags = {for (final t in await db.tagDao.getAll()) t.id: t};
    for (final task in tasks) {
      final mark = task.done ? '[x]' : '[ ]';
      final tag = task.tagId == null ? '' : '  #${tags[task.tagId]?.name}';
      print('${task.id.toString().padLeft(3)}  $mark ${task.title}$tag');
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

class TimeCommand extends Command {
  TimeCommand(this.db) {
    addSubcommand(TimeAddCommand(db));
    addSubcommand(TimeListCommand(db));
  }

  final ClockworkDatabase db;

  @override
  String get name => 'time';

  @override
  String get description => 'Track worked time';
}

class TimeAddCommand extends Command {
  TimeAddCommand(this.db) {
    argParser
      ..addOption('tag', abbr: 't', help: 'Tag name or id')
      ..addOption('task', help: 'Task id')
      ..addOption('date', abbr: 'd', help: 'Date (YYYY-MM-DD)')
      ..addOption('start', abbr: 's', help: 'Start time (HH:MM)')
      ..addOption('end', abbr: 'e', help: 'End time (HH:MM, default: now)')
      ..addOption('notes', abbr: 'n');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'add';

  @override
  String get description =>
      'Add a time entry.\n'
      'Examples:\n'
      '  clockwork time add 1h30m --tag project\n'
      '  clockwork time add --tag project --start 09:00 --end 11:15\n'
      '  clockwork time add 45m --task 3';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    Duration? duration;
    if (rest.isNotEmpty) duration = parseDuration(rest.first);

    final startOption = argResults!['start'] as String?;
    final endOption = argResults!['end'] as String?;
    final date = parseDateOption(argResults!['date'] as String?);
    final now = DateTime.now();

    DateTime start;
    DateTime end;
    if (startOption != null && endOption != null) {
      final s = parseTime(startOption);
      final e = parseTime(endOption);
      start = DateTime(date.year, date.month, date.day, s.hour, s.minute);
      end = DateTime(date.year, date.month, date.day, e.hour, e.minute);
    } else if (startOption != null) {
      if (duration == null) {
        throw UsageException('Duration required with --start', usage);
      }
      final s = parseTime(startOption);
      start = DateTime(date.year, date.month, date.day, s.hour, s.minute);
      end = start.add(duration);
    } else if (duration != null) {
      end = date == DateTime(now.year, now.month, now.day) && endOption == null
          ? now
          : DateTime(date.year, date.month, date.day, now.hour, now.minute);
      if (endOption != null) {
        final e = parseTime(endOption);
        end = DateTime(date.year, date.month, date.day, e.hour, e.minute);
      }
      start = end.subtract(duration);
    } else {
      throw UsageException('Provide a duration and/or --start/--end', usage);
    }

    if (!end.isAfter(start)) {
      stderr.writeln('End must be after start');
      exitCode = 1;
      return;
    }

    int? tagId;
    final tagOption = argResults!['tag'] as String?;
    if (tagOption != null) {
      final tag = await findTag(db, tagOption);
      if (tag == null) {
        stderr.writeln('Tag "$tagOption" not found');
        exitCode = 1;
        return;
      }
      tagId = tag.id;
    }

    int? taskId;
    final taskOption = argResults!['task'] as String?;
    if (taskOption != null) {
      taskId = int.tryParse(taskOption);
      if (taskId == null) throw UsageException('Invalid task id', usage);
    }

    final id = await db.timeEntryDao.createEntry(
      TimeEntriesCompanion.insert(
        start: start,
        end: end,
        tagId: Value(tagId),
        taskId: Value(taskId),
        notes: Value(argResults!['notes'] as String?),
      ),
    );
    print(
      'Added time entry #$id: '
      '${DateFormat.Hm().format(start)}-${DateFormat.Hm().format(end)} '
      '(${formatDuration(end.difference(start))})',
    );
  }
}

class TimeListCommand extends Command {
  TimeListCommand(this.db) {
    argParser.addOption('date', abbr: 'd', help: 'Date (YYYY-MM-DD)');
  }

  final ClockworkDatabase db;

  @override
  String get name => 'list';

  @override
  String get description => 'List time entries';

  @override
  Future<void> run() async {
    final date = parseDateOption(argResults!['date'] as String?);
    final next = date.add(const Duration(days: 1));
    final entries = await db.timeEntryDao.watchRange(date, next).first;
    entries.sort((a, b) => a.start.compareTo(b.start));
    if (entries.isEmpty) {
      print('No time entries on ${dateKey(date)}');
      return;
    }
    final tags = {for (final t in await db.tagDao.getAll()) t.id: t};
    var total = Duration.zero;
    for (final entry in entries) {
      final tag = entry.tagId == null ? '' : '  #${tags[entry.tagId]?.name}';
      final notes = entry.notes == null ? '' : '  ${entry.notes}';
      final d = entryDuration(entry.start, entry.end);
      total += d;
      print(
        '${entry.id.toString().padLeft(3)}  '
        '${DateFormat.Hm().format(entry.start)}-'
        '${DateFormat.Hm().format(entry.end)}  '
        '${formatDuration(d).padLeft(9)}$tag$notes',
      );
    }
    print('Total: ${formatDuration(total)}');
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
    if (tasks.isEmpty) {
      print('  (none)');
    }
    for (final task in tasks) {
      print('  ${task.done ? '[x]' : '[ ]'} ${task.title}');
    }
    print('');
    final next = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final entries = await db.timeEntryDao.watchRange(start, next).first;
    entries.sort((a, b) => a.start.compareTo(b.start));
    final tags = {for (final t in await db.tagDao.getAll()) t.id: t};
    var total = Duration.zero;
    print('== Time ==');
    if (entries.isEmpty) {
      print('  (none)');
    }
    for (final entry in entries) {
      final tag = entry.tagId == null ? '' : '  #${tags[entry.tagId]?.name}';
      final d = entryDuration(entry.start, entry.end);
      total += d;
      print(
        '  ${DateFormat.Hm().format(entry.start)}-'
        '${DateFormat.Hm().format(entry.end)}  '
        '${formatDuration(d)}$tag',
      );
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
    final nextMonday = monday.add(const Duration(days: 7));
    final entries = await db.timeEntryDao.watchRange(monday, nextMonday).first;
    final tags = {for (final t in await db.tagDao.getAll()) t.id: t};

    final perDay = <String, Duration>{};
    final perTag = <int, Duration>{};
    var total = Duration.zero;
    for (final entry in entries) {
      final d = entryDuration(entry.start, entry.end);
      total += d;
      final key = dateKey(entry.start);
      perDay[key] = (perDay[key] ?? Duration.zero) + d;
      if (entry.tagId != null) {
        perTag[entry.tagId!] = (perTag[entry.tagId!] ?? Duration.zero) + d;
      }
    }

    print(
      '== Week ${DateFormat.MMMd().format(monday)} - '
      '${DateFormat.MMMd().format(nextMonday.subtract(const Duration(days: 1)))} ==',
    );
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final key = dateKey(day);
      final d = perDay[key];
      print(
        '  ${DateFormat.E().format(day)} ${day.day.toString().padLeft(2)}  '
        '${d == null ? '-' : formatDuration(d)}',
      );
    }
    print('');
    for (final tagId in perTag.keys) {
      print('  #${tags[tagId]?.name ?? tagId}: ${formatDuration(perTag[tagId]!)}');
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
    ..addCommand(TagCommand(db))
    ..addCommand(TaskCommand(db))
    ..addCommand(TimeCommand(db))
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
