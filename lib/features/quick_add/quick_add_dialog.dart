import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

/// Minimal quick-add widget opened from the system tray: just the amount
/// of hours to add to today and a plus button.
class QuickAddDialog extends StatefulWidget {
  /// Creates the tray quick-add dialog.
  const QuickAddDialog({super.key});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final _hoursController = TextEditingController(text: '1');

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return null;
    return (hours * 60).round();
  }

  Future<void> _add() async {
    final minutes = _minutes;
    if (minutes == null) return;
    final now = DateTime.now();
    final deps = ClockworkScope.of(context);
    await deps.timeEntryRepository.createEntry(
      TimeEntriesCompanion.insert(
        date: dateKey(now),
        minutes: minutes,
        tagId: const Value(null),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _minutes;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.quickAddTitle),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
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
              onSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: minutes != null ? _add : null,
            icon: const Icon(Icons.add),
            iconSize: 32,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
      ],
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
  final _hoursController = TextEditingController(text: '1');

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  int? get _minutes {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return null;
    return (hours * 60).round();
  }

  Future<void> _add() async {
    final minutes = _minutes;
    if (minutes == null) return;
    final now = DateTime.now();
    final deps = ClockworkScope.of(context);
    await deps.timeEntryRepository.createEntry(
      TimeEntriesCompanion.insert(
        date: dateKey(now),
        minutes: minutes,
        tagId: const Value(null),
      ),
    );
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _minutes;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.hoursFieldLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
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
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: minutes != null ? _add : null,
                icon: const Icon(Icons.add),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => widget.onComplete?.call(),
                child: Text(l10n.dialogCancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
