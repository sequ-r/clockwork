import 'package:clockwork/database/database.dart';

/// Repository managing task scheduling, status, and assignment.
class TaskRepository {
  /// Creates the repository with [taskDao].
  const TaskRepository({required this.taskDao});

  /// Data access object for tasks.
  final TaskDao taskDao;

  /// Reactive stream of tasks scheduled on [date] (`YYYY-MM-DD`).
  Stream<List<Task>> watchForDate(String date) => taskDao.watchForDate(date);

  /// Reactive stream of tasks scheduled on any of [dates].
  Stream<List<Task>> watchDateRange(Iterable<String> dates) =>
      taskDao.watchDateRange(dates);

  /// One-shot fetch of tasks scheduled on [date].
  Future<List<Task>> getForDate(String date) => taskDao.getForDate(date);

  /// Inserts a new task and returns the inserted row ID.
  Future<int> createTask(TasksCompanion companion) =>
      taskDao.createTask(companion);

  /// Updates an existing task.
  Future<bool> updateTask(Task task) => taskDao.updateTask(task);

  /// Sets the completion status of the task matching [id].
  Future<int> setDone(int id, bool done) => taskDao.setDone(id, done);

  /// Deletes the task matching [id].
  Future<int> deleteTask(int id) => taskDao.deleteTask(id);
}
