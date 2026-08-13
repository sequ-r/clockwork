import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import '../../core/providers/database.dart';

/// Minimal quick-add widget opened from the system tray: just the amount
/// of hours to add to today and a plus button.
class QuickAddDialog extends ConsumerStatefulWidget {
  /// Creates the tray quick-add dialog.
  const QuickAddDialog({super.key});

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
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
    await ref
        .read(timeEntryDaoProvider)
        .createEntry(
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

    return AlertDialog(
      title: const Text('Quick add'),
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Standalone popup view for quick time entry from the system tray.
class QuickAddPopupView extends ConsumerStatefulWidget {
  /// Creates the quick add popup view.
  const QuickAddPopupView({super.key, this.onComplete});

  /// Callback executed on completion or cancel.
  final VoidCallback? onComplete;

  @override
  ConsumerState<QuickAddPopupView> createState() => _QuickAddPopupViewState();
}

class _QuickAddPopupViewState extends ConsumerState<QuickAddPopupView> {
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
    await ref
        .read(timeEntryDaoProvider)
        .createEntry(
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hours:', style: Theme.of(context).textTheme.titleMedium),
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
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
