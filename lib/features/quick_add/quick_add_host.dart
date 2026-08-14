import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/features/quick_add/quick_add_dialog.dart';
import 'package:flutter/material.dart';

/// Listens to `quickAddRequestNotifier` and shows a [QuickAddDialog] each
/// time a fresh request arrives.
class QuickAddDialogHost extends StatefulWidget {
  /// Wraps [child] and opens [QuickAddDialog] whenever the tray requests.
  const QuickAddDialogHost({super.key, required this.child});

  /// The widget tree underneath the host.
  final Widget child;

  @override
  State<QuickAddDialogHost> createState() => _QuickAddDialogHostState();
}

class _QuickAddDialogHostState extends State<QuickAddDialogHost> {
  int? _lastRequest;
  Listenable? _listenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appVm = ClockworkScope.of(context).appViewModel;
    final notifier = appVm.quickAddRequestNotifier;
    if (_listenable != notifier) {
      _listenable?.removeListener(_onRequest);
      _listenable = notifier;
      _lastRequest = notifier.value;
      _listenable?.addListener(_onRequest);
    }
  }

  void _onRequest() {
    final appVm = ClockworkScope.of(context).appViewModel;
    final notifier = appVm.quickAddRequestNotifier;
    if (notifier.value != _lastRequest && notifier.value > 0) {
      _lastRequest = notifier.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => const QuickAddDialog(),
        );
      });
    }
  }

  @override
  void dispose() {
    _listenable?.removeListener(_onRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
