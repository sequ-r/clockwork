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
}
