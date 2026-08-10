import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import '../../providers/providers.dart';

/// Minimal quick-add widget opened from the system tray: just the amount
/// of hours to add to today and a plus button.
class QuickAddDialog extends ConsumerStatefulWidget {
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
