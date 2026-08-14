import 'package:clockwork/app/tokens.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

/// Dialog that lists every tag, with totals, and lets the user add or
/// edit one.
class TagManagerDialog extends StatelessWidget {
  /// Creates the tag manager dialog.
  const TagManagerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Tag>>(
      stream: deps.tagRepository.watchAll(),
      builder: (context, tagsSnapshot) {
        final tags = tagsSnapshot.data ?? const [];
        final byId = {for (final t in tags) t.id: t};

        return StreamBuilder<List<TimeEntry>>(
          stream: deps.timeEntryRepository.watchDateRange(
            deps.appViewModel.visibleDateKeys,
          ),
          builder: (context, entriesSnapshot) {
            final entries = entriesSnapshot.data ?? const [];
            final totals = <int, Duration>{};
            for (final entry in entries) {
              final tagId = entry.tagId;
              if (tagId == null) continue;
              totals[tagId] =
                  (totals[tagId] ?? Duration.zero) +
                  Duration(minutes: entry.minutes);
            }

            return AlertDialog(
              title: Text(l10n.projectsDialogTitle),
              content: SizedBox(
                width: 440,
                height: 420,
                child: tags.isEmpty
                    ? Center(child: Text(l10n.noProjectsYet))
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
                                  : Text(
                                      'under '
                                      '${byId[tag.parentId]?.name ?? "?"}',
                                    ),
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
                  child: Text(l10n.addProjectButton),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.dialogClose),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Create-or-edit dialog for a single tag.
class TagEditDialog extends StatefulWidget {
  /// Opens the dialog for [tag], or for a new tag when omitted.
  const TagEditDialog({super.key, this.tag});

  /// Existing tag to edit; null creates a new one.
  final Tag? tag;

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
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
    final repo = ClockworkScope.of(context).tagRepository;
    if (_isNew) {
      await repo.createTag(
        TagsCompanion.insert(
          name: name,
          color: _color,
          parentId: Value(_parentId),
        ),
      );
    } else {
      await repo.updateTag(
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
    final repo = ClockworkScope.of(context).tagRepository;
    await repo.deleteTag(widget.tag!.id);
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
        final possibleParents = tags
            .where((t) => t.id != widget.tag?.id)
            .toList();

        return AlertDialog(
          title: Text(_isNew ? l10n.newProject : l10n.editProject),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.projectName),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _parentId,
                  decoration: InputDecoration(labelText: l10n.parentProject),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
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

/// Standalone popup view for managing projects from the system tray.
class TagManagerPopupView extends StatelessWidget {
  /// Creates the project manager popup view.
  const TagManagerPopupView({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Tag>>(
      stream: deps.tagRepository.watchAll(),
      builder: (context, tagsSnapshot) {
        final tags = tagsSnapshot.data ?? const [];
        final byId = {for (final t in tags) t.id: t};

        return StreamBuilder<List<TimeEntry>>(
          stream: deps.timeEntryRepository.watchDateRange(
            deps.appViewModel.visibleDateKeys,
          ),
          builder: (context, entriesSnapshot) {
            final entries = entriesSnapshot.data ?? const [];
            final totals = <int, Duration>{};
            for (final entry in entries) {
              final tagId = entry.tagId;
              if (tagId == null) continue;
              totals[tagId] =
                  (totals[tagId] ?? Duration.zero) +
                  Duration(minutes: entry.minutes);
            }

            return Column(
              children: [
                Expanded(
                  child: tags.isEmpty
                      ? Center(child: Text(l10n.noProjectsYet))
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    : Text(
                                        'under '
                                        '${byId[tag.parentId]?.name ?? "?"}',
                                      ),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => const TagEditDialog(),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addProjectButton),
                      ),
                      FilledButton(
                        onPressed: () => deps.trayService.closeTrayPopup(),
                        child: Text(l10n.dialogClose),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
