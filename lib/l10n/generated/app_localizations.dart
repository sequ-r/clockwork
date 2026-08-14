import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title shown in the title bar
  ///
  /// In en, this message translates to:
  /// **'Clockwork'**
  String get appTitle;

  /// Greeting shown before noon on the Today pane
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get todayGreetingMorning;

  /// Greeting shown between noon and 6pm on the Today pane
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get todayGreetingAfternoon;

  /// Greeting shown after 6pm on the Today pane
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get todayGreetingEvening;

  /// Hint shown inside the quick-add task input
  ///
  /// In en, this message translates to:
  /// **'Add a task...'**
  String get todayAddTaskPlaceholder;

  /// Empty-state message on the Today pane
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day'**
  String get todayNoTasks;

  /// Heading above the list of time entries for the selected day
  ///
  /// In en, this message translates to:
  /// **'Logged time'**
  String get todayLoggedTimeHeader;

  /// FAB label that opens the Add Time dialog
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTimeButton;

  /// Tooltip shown on the warning icon when a day exceeds the limit
  ///
  /// In en, this message translates to:
  /// **'Over the {hours}h working limit'**
  String overLimitTooltip(int hours);

  /// Tooltip for the projects dropdown button in the app bar
  ///
  /// In en, this message translates to:
  /// **'Projects menu'**
  String get projectsMenuTooltip;

  /// Label for managing projects
  ///
  /// In en, this message translates to:
  /// **'Manage projects'**
  String get manageProjects;

  /// Label for creating a new project
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// Dialog title for editing a project
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// Filter chip label for viewing all projects
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allProjects;

  /// Label for project name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectName;

  /// Label for parent project dropdown field
  ///
  /// In en, this message translates to:
  /// **'Parent project'**
  String get parentProject;

  /// Dropdown option for no selection
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOption;

  /// Cancel button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Save button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// Delete button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// Close button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Add button text in dialogs
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dialogAdd;

  /// Empty state when no projects exist
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Add one below.'**
  String get noProjectsYet;

  /// Button to add a project
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProjectButton;

  /// Title of the quick add popup/dialog
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAddTitle;

  /// Title of the tray quick add window
  ///
  /// In en, this message translates to:
  /// **'Quick add time'**
  String get quickAddTimeTitle;

  /// Hours label
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// Hours field label
  ///
  /// In en, this message translates to:
  /// **'Hours:'**
  String get hoursFieldLabel;

  /// Comment input label
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentLabel;

  /// Tag / project input label
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tagLabel;

  /// Task selection label
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskLabel;

  /// Title for the edit task dialog
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTaskTitle;

  /// Task title input label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleLabel;

  /// Task notes input label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get taskNotesLabel;

  /// Bottom navigation label for Today tab
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// Bottom navigation label for Calendar tab
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTab;

  /// Segmented button label for Week view
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekSegment;

  /// Segmented button label for Month view
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthSegment;

  /// Tooltip for navigating to previous period
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousTooltip;

  /// Tooltip for navigating to next period
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextTooltip;

  /// Tooltip for navigating to today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTooltip;

  /// Tooltip for deleting a time entry
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTooltip;

  /// Default title for a time entry with no notes or tag
  ///
  /// In en, this message translates to:
  /// **'Time entry'**
  String get defaultTimeEntryTitle;

  /// Title for the projects dialog
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsDialogTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
