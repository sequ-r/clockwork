import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/features/clock/weekly_clock_view_model.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Background of the weekly clock screen (from the Clockwork design).
const clockBackground = Color(0xFF2E2D2D);

/// Accent color of the clock screen controls.
const clockAccent = Color(0xFF6750A4);

/// Main screen: shows the total worked hours for the current week as a
/// large digital clock, with a stepper to add or remove time.
class WeeklyClockScreen extends StatefulWidget {
  /// Creates the weekly clock screen.
  const WeeklyClockScreen({super.key});

  @override
  State<WeeklyClockScreen> createState() => _WeeklyClockScreenState();
}

class _WeeklyClockScreenState extends State<WeeklyClockScreen> {
  WeeklyClockViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= WeeklyClockViewModel(
      repository: ClockworkScope.of(context).timeEntryRepository,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _confirm(WeeklyClockViewModel vm) async {
    final isAdd = vm.isAddAction;
    final amount = vm.pendingLabel;
    await vm.confirm();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          isAdd ? l10n.clockAddedToast(amount) : l10n.clockRemovedToast(amount),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = _viewModel;
    if (vm == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: clockBackground,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WeekTotalLabel(label: l10n.clockTotalWorkedHours),
                      _ClockDisplay(label: vm.weekTotalLabel),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ControlsRow(
                          viewModel: vm,
                          addLabel: vm.isAddAction
                              ? l10n.clockAddButton
                              : l10n.clockRemoveButton,
                          onConfirm: () => _confirm(vm),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeekTotalLabel extends StatelessWidget {
  const _WeekTotalLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        color: Colors.white,
      ),
    );
  }
}

class _ClockDisplay extends StatelessWidget {
  const _ClockDisplay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 128,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.viewModel,
    required this.addLabel,
    required this.onConfirm,
  });

  final WeeklyClockViewModel viewModel;
  final String addLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmountStepper(viewModel: viewModel),
          const SizedBox(width: 12),
          _ConfirmButton(label: addLabel, onConfirm: onConfirm),
        ],
      ),
    );
  }
}

class _AmountStepper extends StatelessWidget {
  const _AmountStepper({required this.viewModel});

  final WeeklyClockViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: clockAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.clockDecreaseTooltip,
            color: Colors.white,
            onPressed: viewModel.canDecrease ? viewModel.decrement : null,
            icon: const Icon(Icons.remove),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Text(
              viewModel.pendingLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Color(0xFFF5F5F5),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.clockIncreaseTooltip,
            color: Colors.white,
            onPressed: viewModel.canIncrease ? viewModel.increment : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.label, required this.onConfirm});

  final String label;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: clockAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Icons.check),
      label: Text(label),
    );
  }
}
