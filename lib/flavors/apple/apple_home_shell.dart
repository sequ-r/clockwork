import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/features/calendar/calendar_panel.dart';
import 'package:clockwork/features/quick_add/add_time_dialog.dart';
import 'package:clockwork/features/quick_add/quick_add_dialog.dart';
import 'package:clockwork/features/quick_add/quick_add_host.dart';
import 'package:clockwork/features/tags/tag_manager_dialog.dart';
import 'package:clockwork/features/today/today_screen.dart';
import 'package:clockwork/features/today/widgets/tag_filter_bar.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:clockwork/services/tray_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Apple (macOS / iOS) Shell utilizing Cupertino design language and native controls.
class AppleHomeShell extends StatefulWidget {
  /// Creates the Apple home shell.
  const AppleHomeShell({super.key});

  @override
  State<AppleHomeShell> createState() => _AppleHomeShellState();
}

class _AppleHomeShellState extends State<AppleHomeShell> with WindowListener {
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

  void _openProjectsActionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.projectsMenuTooltip),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (_) => const TagManagerDialog(),
              );
            },
            child: Text(l10n.manageProjects),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (_) => const TagEditDialog(),
              );
            },
            child: Text(l10n.newProject),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
      ),
    );
  }

  void _openAddTimeDialog(BuildContext context) {
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
          return _AppleTrayPopupWindow(
            title: l10n.quickAddTimeTitle,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: QuickAddPopupView(
              onComplete: () => deps.trayService.closeTrayPopup(),
            ),
          );
        }

        if (popupMode == TrayPopupMode.manageProjects) {
          return _AppleTrayPopupWindow(
            title: l10n.manageProjects,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: const TagManagerPopupView(),
          );
        }

        return QuickAddDialogHost(
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(l10n.appTitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _openProjectsActionSheet(context),
                    child: const Icon(CupertinoIcons.folder),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _openAddTimeDialog(context),
                    child: const Icon(CupertinoIcons.add),
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: LayoutBuilder(
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
                    return const _AppleNarrowLayout();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppleTrayPopupWindow extends StatelessWidget {
  const _AppleTrayPopupWindow({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onClose,
          child: const Icon(CupertinoIcons.clear, size: 20),
        ),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [Expanded(child: child)]),
        ),
      ),
    );
  }
}

class _AppleNarrowLayout extends StatelessWidget {
  const _AppleNarrowLayout();

  @override
  Widget build(BuildContext context) {
    final appVm = ClockworkScope.of(context).appViewModel;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: appVm,
      builder: (context, _) {
        final tab = appVm.homeTab;

        return Column(
          children: [
            const TagFilterBar(),
            Expanded(
              child: IndexedStack(
                index: tab,
                children: const [TodayScreen(), CalendarPanel()],
              ),
            ),
            CupertinoTabBar(
              currentIndex: tab,
              onTap: appVm.setHomeTab,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.check_mark_circled),
                  label: l10n.todayTab,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.calendar),
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
