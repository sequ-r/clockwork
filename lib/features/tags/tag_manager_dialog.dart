import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../database/database.dart';
import '../../database/dates.dart';
import '../../core/providers/database.dart';
import '../../core/providers/time_entries.dart';

/// Dialog that lists every tag, with totals, and lets the user add or
/// edit one.
class TagManagerDialog extends ConsumerWidget {
  /// Creates the tag manager dialog.
  const TagManagerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).value ?? [];
    final totals = ref.watch(visibleTagTotalsProvider);
    final byId = {for (final t in tags) t.id: t};

    return AlertDialog(
      title: const Text('Tags & projects'),
      content: SizedBox(
        width: 440,
        height: 420,
        child: tags.isEmpty
            ? const Center(child: Text('No tags yet. Add one below.'))
            : ListView(
                children: [
                  for (final tag in tags)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(tag.color),
                        radius: 8,
                      ),
                      title: Text(tag.name),
                      subtitle: tag.parentId == null
                          ? null
                          : Text('under ${byId[tag.parentId]?.name ?? '?'}'),
                      trailing: totals[tag.id] == null
                          ? null
                          : Text(formatDuration(totals[tag.id]!)),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => TagEditDialog(tag: tag),
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const TagEditDialog(),
          ),
          child: const Text('Add tag'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Create-or-edit dialog for a single tag.
class TagEditDialog extends ConsumerStatefulWidget {
  /// Opens the dialog for [tag], or for a new tag when omitted.
  const TagEditDialog({super.key, this.tag});

  /// Existing tag to edit; null creates a new one.
  final Tag? tag;

  @override
  ConsumerState<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<TagEditDialog> {
  late final TextEditingController _nameController;
  late int _color;
  int? _parentId;

  bool get _isNew => widget.tag == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _color = widget.tag?.color ?? kAutoTagColors.first;
    _parentId = widget.tag?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final dao = ref.read(tagDaoProvider);
    if (_isNew) {
      await dao.createTag(
        TagsCompanion.insert(
          name: name,
          color: _color,
          parentId: Value(_parentId),
        ),
      );
    } else {
      await dao.updateTag(
        widget.tag!.copyWith(
          name: name,
          color: _color,
          parentId: Value(_parentId),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(tagDaoProvider).deleteTag(widget.tag!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider).value ?? [];
    final possibleParents = tags.where((t) => t.id != widget.tag?.id).toList();

    return AlertDialog(
      title: Text(_isNew ? 'New tag' : 'Edit tag'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _parentId,
              decoration: const InputDecoration(labelText: 'Parent project'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final tag in possibleParents)
                  DropdownMenuItem(value: tag.id, child: Text(tag.name)),
              ],
              onChanged: (value) => setState(() => _parentId = value),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in kAutoTagColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(color),
                      child: _color == color
                          ? const Icon(Icons.check, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!_isNew)
          TextButton(onPressed: _delete, child: const Text('Delete')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
