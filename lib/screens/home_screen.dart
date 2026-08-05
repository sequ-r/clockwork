import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../database/dates.dart';
import '../providers/providers.dart';
import '../services/tray_service.dart';
import '../widgets/add_time_dialog.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/tag_manager_dialog.dart';
import '../widgets/task_panel.dart';
import '../widgets/week_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WindowListener {
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

  @override
  Widget build(BuildContext context) {
    final weekTotal = ref.watch(weekTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clockwork'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'Week total: ${formatDuration(weekTotal)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
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
      body: const Column(
        children: [
          TagFilterBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 380, child: TaskPanel()),
                VerticalDivider(width: 1, thickness: 1),
                Expanded(child: WeekView()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const AddTimeDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Track time'),
      ),
    );
  }
}
