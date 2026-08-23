import 'dart:ui' show DisplayFeatureType;

import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/features/calendar/calendar_panel.dart';
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
        body: Column(
          children: [
            const TagFilterBar(),
            Expanded(
              child: TwoPane(
                paneProportion: 0.45,
                panePriority: isLargeScreen
                    ? TwoPanePriority.both
                    : TwoPanePriority.start,
                startPane: const TodayScreen(),
                endPane: const CalendarPanel(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: appVm,
          builder: (context, _) {
            // Hide bottom navigation bar when unfolded or wide enough for
            // two panes.
            if (isLargeScreen) {
              return const SizedBox.shrink();
            }

            final tab = appVm.homeTab;
            return NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: appVm.setHomeTab,
              destinations: [
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddTimeDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addTimeButton),
        ),
      ),
    );
  }
}
