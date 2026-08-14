import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

const _quickPicks = [15, 30, 60, 120, 240];

/// Minimal quick-add dialog opened inside the application: select hours,
/// project, and confirm to add time to today.
class QuickAddDialog extends StatefulWidget {
  /// Creates the tray quick-add dialog.
  const QuickAddDialog({super.key});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _notesController;
  int? _tagId;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '1');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return null;
    return (hours * 60).round();
  }

  void _setHours(double hours) {
    final rounded = (hours * 100).round() / 100;
    _hoursController.text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    setState(() {});
  }

  void _step(double delta) {
    final current = double.tryParse(_hoursController.text.trim()) ?? 0;
    final next = (current + delta).clamp(0.25, 24.0);
    _setHours(next);
  }

  Future<void> _confirm() async {
    final minutes = _minutes;
    if (minutes == null) return;
    final now = DateTime.now();
    final deps = ClockworkScope.of(context);
    final notes = _notesController.text.trim();
    await deps.timeEntryRepository.createEntry(
      TimeEntriesCompanion.insert(
        date: dateKey(now),
        minutes: minutes,
        tagId: Value(_tagId),
        notes: Value(notes.isEmpty ? null : notes),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final minutes = _minutes;

    return StreamBuilder<List<Tag>>(
      stream: deps.tagRepository.watchAll(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const [];

        return AlertDialog(
          title: Text(l10n.quickAddTitle),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _step(-0.5),
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _hoursController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: 'h',
                          isDense: true,
                        ),
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _confirm(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () => _step(0.5),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final pick in _quickPicks)
                      ChoiceChip(
                        label: Text(pick < 60 ? '${pick}m' : '${pick ~/ 60}h'),
                        selected: minutes == pick,
                        onSelected: (_) => _setHours(pick / 60),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _tagId,
                  decoration: InputDecoration(
                    labelText: l10n.projectLabel,
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
                    for (final tag in tags)
                      DropdownMenuItem(
                        value: tag.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: Color(tag.color),
                            ),
                            const SizedBox(width: 8),
                            Text(tag.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _tagId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.commentLabel,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton.icon(
              onPressed: minutes != null ? _confirm : null,
              icon: const Icon(Icons.check),
              label: Text(l10n.confirmButton),
            ),
          ],
        );
      },
    );
  }
}

/// Standalone popup view for quick time entry from the system tray.
class QuickAddPopupView extends StatefulWidget {
  /// Creates the quick add popup view.
  const QuickAddPopupView({super.key, this.onComplete});

  /// Callback executed on completion or cancel.
  final VoidCallback? onComplete;

  @override
  State<QuickAddPopupView> createState() => _QuickAddPopupViewState();
}

class _QuickAddPopupViewState extends State<QuickAddPopupView> {
  late final TextEditingController _hoursController;
  late final TextEditingController _notesController;
  int? _tagId;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '1');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return null;
    return (hours * 60).round();
  }

  void _setHours(double hours) {
    final rounded = (hours * 100).round() / 100;
    _hoursController.text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    setState(() {});
  }

  void _step(double delta) {
    final current = double.tryParse(_hoursController.text.trim()) ?? 0;
    final next = (current + delta).clamp(0.25, 24.0);
    _setHours(next);
  }

  Future<void> _confirm() async {
    final minutes = _minutes;
    if (minutes == null) return;
    final now = DateTime.now();
    final deps = ClockworkScope.of(context);
    final notes = _notesController.text.trim();
    await deps.timeEntryRepository.createEntry(
      TimeEntriesCompanion.insert(
        date: dateKey(now),
        minutes: minutes,
        tagId: Value(_tagId),
        notes: Value(notes.isEmpty ? null : notes),
      ),
    );
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final minutes = _minutes;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Tag>>(
      stream: deps.tagRepository.watchAll(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _step(-0.5),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _hoursController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: 'h',
                        isDense: true,
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _confirm(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () => _step(0.5),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final pick in _quickPicks)
                    ChoiceChip(
                      label: Text(pick < 60 ? '${pick}m' : '${pick ~/ 60}h'),
                      selected: minutes == pick,
                      onSelected: (_) => _setHours(pick / 60),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                initialValue: _tagId,
                decoration: InputDecoration(
                  labelText: l10n.projectLabel,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
                  for (final tag in tags)
                    DropdownMenuItem(
                      value: tag.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 6,
                            backgroundColor: Color(tag.color),
                          ),
                          const SizedBox(width: 8),
                          Text(tag.name),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _tagId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.commentLabel,
                  isDense: true,
                ),
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => widget.onComplete?.call(),
                    child: Text(l10n.dialogCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: minutes != null ? _confirm : null,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.confirmButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
