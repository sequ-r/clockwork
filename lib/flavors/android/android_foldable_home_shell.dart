import 'dart:ui' show DisplayFeatureType;

import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/features/calendar/calendar_panel.dart';
import 'package:clockwork/features/clock/weekly_clock_screen.dart';
import 'package:clockwork/features/quick_add/add_time_dialog.dart';
import 'package:clockwork/features/quick_add/quick_add_host.dart';
import 'package:clockwork/features/tags/tag_manager_dialog.dart';
import 'package:clockwork/features/today/today_screen.dart';
import 'package:clockwork/features/today/widgets/tag_filter_bar.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';

enum _AndroidMenuAction { manageProjects, addProject }

/// Android Shell supporting Material 3 Expressive and Foldable dual-screen
/// postures.
class AndroidFoldableHomeShell extends StatelessWidget {
  /// Creates the Android foldable-aware home shell.
  const AndroidFoldableHomeShell({super.key});

  void _openAddTimeDialog(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const AddTimeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final appVm = deps.appViewModel;
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isFoldableFolded = mediaQuery.displayFeatures.any(
      (f) =>
          f.type == DisplayFeatureType.hinge ||
          f.type == DisplayFeatureType.fold,
    );
    final isLargeScreen = mediaQuery.size.width >= 720 || isFoldableFolded;

    return QuickAddDialogHost(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            PopupMenuButton<_AndroidMenuAction>(
              tooltip: l10n.projectsMenuTooltip,
              icon: const Icon(Icons.folder_outlined),
              onSelected: (action) {
                switch (action) {
                  case _AndroidMenuAction.manageProjects:
                    showDialog<void>(
                      context: context,
                      builder: (_) => const TagManagerDialog(),
                    );
                  case _AndroidMenuAction.addProject:
                    showDialog<void>(
                      context: context,
                      builder: (_) => const TagEditDialog(),
                    );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _AndroidMenuAction.manageProjects,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_special_outlined),
                      const SizedBox(width: 12),
                      Text(l10n.manageProjects),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _AndroidMenuAction.addProject,
                  child: Row(
                    children: [
                      const Icon(Icons.create_new_folder_outlined),
                      const SizedBox(width: 12),
                      Text(l10n.newProject),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: appVm,
          builder: (context, _) {
            final tab = appVm.homeTab;
            return IndexedStack(
              index: tab == 0 ? 0 : 1,
              children: [
                const WeeklyClockScreen(),
                Column(
                  children: [
                    const TagFilterBar(),
                    Expanded(
                      child: TwoPane(
                        paneProportion: 0.45,
                        panePriority: !isLargeScreen
                            ? (tab == 1
                                  ? TwoPanePriority.start
                                  : TwoPanePriority.end)
                            : TwoPanePriority.both,
                        startPane: const TodayScreen(),
                        endPane: const CalendarPanel(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: appVm,
          builder: (context, _) {
            final tab = appVm.homeTab;
            return NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: appVm.setHomeTab,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.schedule),
                  label: l10n.clockTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.checklist),
                  label: l10n.todayTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month),
                  label: l10n.calendarTab,
                ),
              ],
            );
          },
        ),
        floatingActionButton: ListenableBuilder(
          listenable: appVm,
          builder: (context, _) {
            // The clock screen has its own inline add controls.
            if (appVm.homeTab == 0) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              onPressed: () => _openAddTimeDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addTimeButton),
            );
          },
        ),
      ),
    );
  }
}
