import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/features/calendar/calendar_panel.dart';
import 'package:clockwork/features/clock/weekly_clock_screen.dart';
import 'package:clockwork/features/quick_add/add_time_dialog.dart';
import 'package:clockwork/features/quick_add/quick_add_dialog.dart';
import 'package:clockwork/features/quick_add/quick_add_host.dart';
import 'package:clockwork/features/tags/tag_manager_dialog.dart';
import 'package:clockwork/features/today/today_screen.dart';
import 'package:clockwork/features/today/widgets/tag_filter_bar.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:clockwork/services/tray_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

enum _LinuxMenuAction { manageProjects, addProject }

/// Linux Desktop Shell utilizing Canonical Yaru widgets and system integration.
class LinuxHomeShell extends StatefulWidget {
  /// Creates the Linux desktop home shell.
  const LinuxHomeShell({super.key});

  @override
  State<LinuxHomeShell> createState() => _LinuxHomeShellState();
}

class _LinuxHomeShellState extends State<LinuxHomeShell> with WindowListener {
  bool _initializedTray = false;
  TrayService? _trayService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = ClockworkScope.of(context);
    _trayService = deps.trayService;
    if (!_initializedTray && TrayService.isSupported) {
      _initializedTray = true;
      windowManager.addListener(this);
      final trayService = _trayService!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trayService.init();
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
    _trayService?.closeTrayPopup();
  }

  @override
  void onWindowMinimize() => windowManager.hide();

  void _openAddTimeDialog() {
    showDialog<void>(context: context, builder: (_) => const AddTimeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final deps = ClockworkScope.of(context);
    final appVm = deps.appViewModel;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: appVm,
      builder: (context, _) {
        final popupMode = appVm.activeTrayPopup;

        if (popupMode == TrayPopupMode.quickAdd) {
          return _LinuxTrayPopupWindow(
            title: l10n.quickAddTimeTitle,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: QuickAddPopupView(
              onComplete: () => deps.trayService.closeTrayPopup(),
            ),
          );
        }

        if (popupMode == TrayPopupMode.manageProjects) {
          return _LinuxTrayPopupWindow(
            title: l10n.manageProjects,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: const TagManagerPopupView(),
          );
        }

        return QuickAddDialogHost(
          child: Scaffold(
            appBar: YaruTitleBar(
              title: Text(l10n.appTitle),
              leading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.schedule, size: 20),
              ),
              actions: [
                PopupMenuButton<_LinuxMenuAction>(
                  tooltip: l10n.projectsMenuTooltip,
                  icon: const Icon(Icons.folder_outlined),
                  onSelected: (action) {
                    switch (action) {
                      case _LinuxMenuAction.manageProjects:
                        showDialog<void>(
                          context: context,
                          builder: (_) => const TagManagerDialog(),
                        );
                      case _LinuxMenuAction.addProject:
                        showDialog<void>(
                          context: context,
                          builder: (_) => const TagEditDialog(),
                        );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _LinuxMenuAction.manageProjects,
                      child: Row(
                        children: [
                          const Icon(Icons.folder_special_outlined),
                          const SizedBox(width: 12),
                          Text(l10n.manageProjects),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _LinuxMenuAction.addProject,
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
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                if (isWide) {
                  return _LinuxWideLayout(appViewModel: appVm, l10n: l10n);
                }
                return _LinuxNarrowLayout(l10n: l10n);
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
                  onPressed: _openAddTimeDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addTimeButton),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LinuxTrayPopupWindow extends StatelessWidget {
  const _LinuxTrayPopupWindow({
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
    final l10n = AppLocalizations.of(context)!;

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
                    tooltip: l10n.dialogClose,
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

class _LinuxWideLayout extends StatelessWidget {
  const _LinuxWideLayout({required this.appViewModel, required this.l10n});

  final AppViewModel appViewModel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appViewModel,
      builder: (context, _) {
        final tab = appViewModel.homeTab;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: tab,
              onDestinationSelected: appViewModel.setHomeTab,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.schedule),
                  label: Text(l10n.clockTab),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.checklist),
                  label: Text(l10n.todayTab),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(l10n.calendarTab),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: tab,
                children: const [
                  WeeklyClockScreen(),
                  _LinuxTodayPane(),
                  CalendarPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LinuxTodayPane extends StatelessWidget {
  const _LinuxTodayPane();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        TagFilterBar(),
        Expanded(child: TodayScreen()),
      ],
    );
  }
}

class _LinuxNarrowLayout extends StatelessWidget {
  const _LinuxNarrowLayout({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final appVm = ClockworkScope.of(context).appViewModel;

    return ListenableBuilder(
      listenable: appVm,
      builder: (context, _) {
        final tab = appVm.homeTab;

        return Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: tab,
                children: const [
                  WeeklyClockScreen(),
                  _LinuxTodayPane(),
                  CalendarPanel(),
                ],
              ),
            ),
            NavigationBar(
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
            ),
          ],
        );
      },
    );
  }
}
