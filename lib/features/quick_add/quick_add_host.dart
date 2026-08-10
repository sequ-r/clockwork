import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'quick_add_dialog.dart';

/// Listens to [quickAddRequestProvider] and shows a [QuickAddDialog] each
/// time a fresh request arrives.
///
/// Replaces the previous polling pattern (`_lastQuickAddRequest` field on
/// the home screen) with a proper side-effect channel via `ref.listen`.
/// Using a counter as the event payload makes the dialog idempotent: every
/// tray click produces a fresh event even if the dialog was already shown
/// and dismissed.
class QuickAddDialogHost extends ConsumerWidget {
  const QuickAddDialogHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(quickAddRequestProvider, (_, __) {
      // Defer to the next frame so we don't try to show a dialog while
      // the parent widget is still building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => const QuickAddDialog(),
        );
      });
    });
    return child;
  }
}
