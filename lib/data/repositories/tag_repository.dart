import 'package:clockwork/database/database.dart';

/// Repository managing project and tag entities.
class TagRepository {
  /// Creates the repository with [tagDao].
  const TagRepository({required this.tagDao});

  /// Data access object for tags.
  final TagDao tagDao;

  /// Reactive stream of all tags.
  Stream<List<Tag>> watchAll() => tagDao.watchAll();

  /// One-shot fetch of all tags.
  Future<List<Tag>> getAll() => tagDao.getAll();

  /// Inserts a new tag and returns the inserted row ID.
  Future<int> createTag(TagsCompanion companion) => tagDao.createTag(companion);

  /// Replaces the tag matching [tag.id].
  Future<bool> updateTag(Tag tag) => tagDao.updateTag(tag);

  /// Deletes the tag matching [id].
  Future<int> deleteTag(int id) => tagDao.deleteTag(id);
}
