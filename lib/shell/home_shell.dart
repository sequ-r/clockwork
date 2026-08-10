import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../features/calendar/calendar_panel.dart';
import '../features/quick_add/add_time_dialog.dart';
import '../features/quick_add/quick_add_host.dart';
import '../features/tags/tag_manager_dialog.dart';
import '../features/today/today_screen.dart';
import '../features/today/widgets/tag_filter_bar.dart';
import '../services/tray_service.dart';

/// Top-level shell of the app: AppBar, responsive layout (wide vs narrow),
/// FAB, tray integration.
///
/// Concrete panes (Today / Calendar / Tags) are mounted as children of
/// this widget.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (TrayService.isSupported) {
      windowManager.addListener(this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(trayServiceProvider).init();
      });
    }
  }

  @override
  void dispose() {
    if (TrayService.isSupported) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() => windowManager.hide();

  @override
  void onWindowMinimize() => windowManager.hide();

  void _openAddTimeDialog() {
    showDialog<void>(context: context, builder: (_) => const AddTimeDialog());
  }

  @override
  Widget build(BuildContext context) {
    return QuickAddDialogHost(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clockwork'),
          actions: [
            IconButton(
              tooltip: 'Manage tags',
              icon: const Icon(Icons.label_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const TagManagerDialog(),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            if (isWide) {
              return Column(
                children: [
                  const TagFilterBar(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        SizedBox(width: 380, child: TodayScreen()),
                        VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: CalendarPanel()),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const _NarrowLayout();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddTimeDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add time'),
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatefulWidget {
  const _NarrowLayout();

  @override
  State<_NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<_NarrowLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TagFilterBar(),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [TodayScreen(), CalendarPanel()],
          ),
        ),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Today'),
            NavigationDestination(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
          ],
        ),
      ],
    );
  }
}
