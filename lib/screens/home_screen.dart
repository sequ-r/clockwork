import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/providers.dart';
import '../services/tray_service.dart';
import '../widgets/add_time_dialog.dart';
import '../widgets/calendar_panel.dart';
import '../widgets/left_panel.dart';
import '../widgets/quick_add_dialog.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/tag_manager_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WindowListener {
  int _lastQuickAddRequest = 0;

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
    windowManager.hide();
  }

  @override
  void onWindowMinimize() {
    windowManager.hide();
  }

  void _openAddTimeDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const AddTimeDialog(),
    );
  }

  void _openQuickAddDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const QuickAddDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickAddRequest = ref.watch(quickAddRequestProvider);
    if (quickAddRequest != _lastQuickAddRequest) {
      _lastQuickAddRequest = quickAddRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openQuickAddDialog();
      });
    }

    return Scaffold(
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
                      SizedBox(width: 380, child: LeftPanel()),
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
            children: const [LeftPanel(), CalendarPanel()],
          ),
        ),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist),
              label: 'Today',
            ),
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
