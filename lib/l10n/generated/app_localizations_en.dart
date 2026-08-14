// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clockwork';

  @override
  String get todayGreetingMorning => 'Good morning';

  @override
  String get todayGreetingAfternoon => 'Good afternoon';

  @override
  String get todayGreetingEvening => 'Good evening';

  @override
  String get todayAddTaskPlaceholder => 'Add a task...';

  @override
  String get todayNoTasks => 'No tasks for this day';

  @override
  String get todayLoggedTimeHeader => 'Logged time';

  @override
  String get addTimeButton => 'Add time';

  @override
  String overLimitTooltip(int hours) {
    return 'Over the ${hours}h working limit';
  }

  @override
  String get projectsMenuTooltip => 'Projects menu';

  @override
  String get manageProjects => 'Manage projects';

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get allProjects => 'All';

  @override
  String get projectName => 'Name';

  @override
  String get parentProject => 'Parent project';

  @override
  String get noneOption => 'None';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogSave => 'Save';

  @override
  String get dialogDelete => 'Delete';

  @override
  String get dialogClose => 'Close';

  @override
  String get dialogAdd => 'Add';

  @override
  String get noProjectsYet => 'No projects yet. Add one below.';

  @override
  String get addProjectButton => 'Add project';

  @override
  String get quickAddTitle => 'Quick add';

  @override
  String get quickAddTimeTitle => 'Quick add time';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get hoursFieldLabel => 'Hours:';

  @override
  String get commentLabel => 'Comment';

  @override
  String get tagLabel => 'Tag';

  @override
  String get taskLabel => 'Task';

  @override
  String get editTaskTitle => 'Edit task';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskNotesLabel => 'Notes';

  @override
  String get todayTab => 'Today';

  @override
  String get calendarTab => 'Calendar';

  @override
  String get weekSegment => 'Week';

  @override
  String get monthSegment => 'Month';

  @override
  String get previousTooltip => 'Previous';

  @override
  String get nextTooltip => 'Next';

  @override
  String get todayTooltip => 'Today';

  @override
  String get deleteEntryTooltip => 'Delete entry';

  @override
  String get defaultTimeEntryTitle => 'Time entry';

  @override
  String get projectsDialogTitle => 'Projects';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get projectLabel => 'Project';
}
