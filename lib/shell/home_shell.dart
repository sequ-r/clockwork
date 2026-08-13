import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/providers/ui_state.dart';
import '../features/calendar/calendar_panel.dart';
import '../features/quick_add/add_time_dialog.dart';
import '../features/quick_add/quick_add_dialog.dart';
import '../features/quick_add/quick_add_host.dart';
import '../features/tags/tag_manager_dialog.dart';
import '../features/today/today_screen.dart';
import '../features/today/widgets/tag_filter_bar.dart';
import '../services/tray_service.dart';

enum _ProjectsMenuAction { manageProjects, addProject }

/// Top-level shell of the app: AppBar, responsive layout (wide vs narrow),
/// FAB, tray integration.
///
/// Concrete panes (Today / Calendar / Tags) are mounted as children of
/// this widget.
class HomeShell extends ConsumerStatefulWidget {
  /// Creates the home shell.
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
  void onWindowClose() {
    ref.read(trayServiceProvider).closeTrayPopup();
  }

  @override
  void onWindowMinimize() => windowManager.hide();

  void _openAddTimeDialog() {
    showDialog<void>(context: context, builder: (_) => const AddTimeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final popupMode = ref.watch(activeTrayPopupProvider);

    if (popupMode == TrayPopupMode.quickAdd) {
      return _TrayPopupWindowContainer(
        title: 'Quick add time',
        onClose: () => ref.read(trayServiceProvider).closeTrayPopup(),
        child: QuickAddPopupView(
          onComplete: () => ref.read(trayServiceProvider).closeTrayPopup(),
        ),
      );
    }

    if (popupMode == TrayPopupMode.manageProjects) {
      return _TrayPopupWindowContainer(
        title: 'Manage projects',
        onClose: () => ref.read(trayServiceProvider).closeTrayPopup(),
        child: const TagManagerPopupView(),
      );
    }

    return QuickAddDialogHost(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clockwork'),
          actions: [
            PopupMenuButton<_ProjectsMenuAction>(
              tooltip: 'Projects menu',
              icon: const Icon(Icons.folder_outlined),
              onSelected: (action) {
                switch (action) {
                  case _ProjectsMenuAction.manageProjects:
                    showDialog<void>(
                      context: context,
                      builder: (_) => const TagManagerDialog(),
                    );
                  case _ProjectsMenuAction.addProject:
                    showDialog<void>(
                      context: context,
                      builder: (_) => const TagEditDialog(),
                    );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ProjectsMenuAction.manageProjects,
                  child: Row(
                    children: [
                      Icon(Icons.folder_special_outlined),
                      SizedBox(width: 12),
                      Text('Manage projects'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ProjectsMenuAction.addProject,
                  child: Row(
                    children: [
                      Icon(Icons.create_new_folder_outlined),
                      SizedBox(width: 12),
                      Text('New project'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            if (isWide) {
              return const Column(
                children: [
                  TagFilterBar(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

class _TrayPopupWindowContainer extends StatelessWidget {
  const _TrayPopupWindowContainer({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHigh,
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Close',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    return Column(
      children: [
        const TagFilterBar(),
        Expanded(
          child: IndexedStack(
            index: tab,
            children: const [TodayScreen(), CalendarPanel()],
          ),
        ),
        NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (index) =>
              ref.read(homeTabProvider.notifier).set(index),
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
