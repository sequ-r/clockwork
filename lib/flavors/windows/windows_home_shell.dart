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
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:window_manager/window_manager.dart';

/// Windows Desktop Shell utilizing Microsoft Fluent Design System.
class WindowsHomeShell extends StatefulWidget {
  /// Creates the Windows Fluent home shell.
  const WindowsHomeShell({super.key});

  @override
  State<WindowsHomeShell> createState() => _WindowsHomeShellState();
}

class _WindowsHomeShellState extends State<WindowsHomeShell>
    with WindowListener {
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
    material.showDialog<void>(
      context: context,
      builder: (_) => const AddTimeDialog(),
    );
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
          return _WindowsTrayPopupWindow(
            title: l10n.quickAddTimeTitle,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: QuickAddPopupView(
              onComplete: () => deps.trayService.closeTrayPopup(),
            ),
          );
        }

        if (popupMode == TrayPopupMode.manageProjects) {
          return _WindowsTrayPopupWindow(
            title: l10n.manageProjects,
            onClose: () => deps.trayService.closeTrayPopup(),
            child: const TagManagerPopupView(),
          );
        }

        return QuickAddDialogHost(
          child: NavigationView(
            pane: NavigationPane(
              header: Container(
                height: kOneLineTileHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    const Icon(FluentIcons.clock, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.appTitle,
                      style: FluentTheme.of(context).typography.title,
                    ),
                  ],
                ),
              ),
              selected: appVm.homeTab,
              onChanged: appVm.setHomeTab,
              displayMode: PaneDisplayMode.compact,
              items: [
                PaneItem(
                  icon: const Icon(FluentIcons.check_list),
                  title: Text(l10n.todayTab),
                  body: material.Material(
                    type: material.MaterialType.transparency,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 760;
                        if (isWide) {
                          return const Column(
                            children: [
                              TagFilterBar(),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(width: 380, child: TodayScreen()),
                                    material.VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                    ),
                                    Expanded(child: CalendarPanel()),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const Column(
                          children: [
                            TagFilterBar(),
                            Expanded(child: TodayScreen()),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                PaneItem(
                  icon: const Icon(FluentIcons.calendar),
                  title: Text(l10n.calendarTab),
                  body: const material.Material(
                    type: material.MaterialType.transparency,
                    child: Column(
                      children: [
                        TagFilterBar(),
                        Expanded(child: CalendarPanel()),
                      ],
                    ),
                  ),
                ),
              ],
              footerItems: [
                PaneItemAction(
                  icon: const Icon(FluentIcons.add),
                  title: Text(l10n.addTimeButton),
                  onTap: _openAddTimeDialog,
                ),
                PaneItemAction(
                  icon: const Icon(FluentIcons.folder),
                  title: Text(l10n.manageProjects),
                  onTap: () => material.showDialog<void>(
                    context: context,
                    builder: (_) => const TagManagerDialog(),
                  ),
                ),
                PaneItemAction(
                  icon: const Icon(FluentIcons.new_folder),
                  title: Text(l10n.newProject),
                  onTap: () => material.showDialog<void>(
                    context: context,
                    builder: (_) => const TagEditDialog(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WindowsTrayPopupWindow extends StatelessWidget {
  const _WindowsTrayPopupWindow({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: FluentTheme.of(context).cardColor,
              child: Row(
                children: [
                  const Icon(FluentIcons.clock, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(FluentIcons.chrome_close),
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
