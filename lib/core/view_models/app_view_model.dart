import 'package:clockwork/database/dates.dart';
import 'package:flutter/foundation.dart';

/// Daily working-hours limit after which a warning is shown.
const Duration workingHoursLimit = Duration(hours: 8);

/// Whether [duration] exceeds the daily working-hours limit.
bool isOverLimit(Duration duration) => duration > workingHoursLimit;

/// Available calendar views for the right pane.
enum CalendarView {
  /// Seven-day view, anchored on the week's Monday.
  week,

  /// Month grid, anchored on the first of the month.
  month,
}

/// Modes for standalone popup windows opened from the system tray.
enum TrayPopupMode {
  /// Normal main window view.
  none,

  /// Compact popup window for quick time entry.
  quickAdd,

  /// Compact popup window for managing projects.
  manageProjects,
}

DateTime _todayMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Application-wide UI state manager implementing [ChangeNotifier].
class AppViewModel extends ChangeNotifier {
  /// Creates the application view model with defaults.
  AppViewModel({
    DateTime? initialSelectedDate,
    DateTime? initialCalendarAnchor,
    CalendarView initialCalendarView = CalendarView.week,
  }) : _selectedDate = initialSelectedDate ?? _todayMidnight(),
       _calendarAnchor = initialCalendarAnchor ?? _todayMidnight(),
       _calendarViewMode = initialCalendarView;

  DateTime _selectedDate;
  DateTime _calendarAnchor;
  CalendarView _calendarViewMode;
  int? _tagFilter;
  int _homeTab = 0;
  TrayPopupMode _activeTrayPopup = TrayPopupMode.none;
  final ValueNotifier<int> _quickAddRequestNotifier = ValueNotifier<int>(0);

  /// Currently selected day, displayed in the left pane.
  DateTime get selectedDate => _selectedDate;

  /// Anchor day of the visible calendar in the right pane.
  DateTime get calendarAnchor => _calendarAnchor;

  /// Active calendar view mode (week or month).
  CalendarView get calendarViewMode => _calendarViewMode;

  /// Selected tag filter; null means all tags are visible.
  int? get tagFilter => _tagFilter;

  /// Active tab index in the narrow layout (0 = Today, 1 = Calendar).
  int get homeTab => _homeTab;

  /// Active popup window mode opened from the system tray.
  TrayPopupMode get activeTrayPopup => _activeTrayPopup;

  /// Notifier that fires incremented values on tray quick-add requests.
  ValueListenable<int> get quickAddRequestNotifier => _quickAddRequestNotifier;

  /// Day-keys covered by the visible calendar range.
  List<String> get visibleDateKeys => switch (_calendarViewMode) {
    CalendarView.week => weekKeys(_calendarAnchor),
    CalendarView.month => monthKeys(_calendarAnchor),
  };

  /// Sets the selected date, normalized to midnight.
  void setSelectedDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    notifyListeners();
  }

  /// Sets the calendar anchor date, normalized to midnight.
  void setCalendarAnchor(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    if (_calendarAnchor == normalized) return;
    _calendarAnchor = normalized;
    notifyListeners();
  }

  /// Sets the active calendar view mode.
  void setCalendarViewMode(CalendarView value) {
    if (_calendarViewMode == value) return;
    _calendarViewMode = value;
    notifyListeners();
  }

  /// Sets or clears the active tag filter.
  void setTagFilter(int? value) {
    if (_tagFilter == value) return;
    _tagFilter = value;
    notifyListeners();
  }

  /// Sets the active tab index for narrow screen navigation.
  void setHomeTab(int index) {
    if (_homeTab == index) return;
    _homeTab = index;
    notifyListeners();
  }

  /// Sets the active tray popup mode.
  void setActiveTrayPopup(TrayPopupMode mode) {
    if (_activeTrayPopup == mode) return;
    _activeTrayPopup = mode;
    notifyListeners();
  }

  /// Fires a quick-add request from the system tray.
  void requestQuickAdd() {
    _quickAddRequestNotifier.value++;
  }

  @override
  void dispose() {
    _quickAddRequestNotifier.dispose();
    super.dispose();
  }
}
