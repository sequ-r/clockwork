// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected day, shown in the left pane.

@ProviderFor(SelectedDate)
final selectedDateProvider = SelectedDateProvider._();

/// Currently selected day, shown in the left pane.
final class SelectedDateProvider
    extends $NotifierProvider<SelectedDate, DateTime> {
  /// Currently selected day, shown in the left pane.
  SelectedDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDateHash();

  @$internal
  @override
  SelectedDate create() => SelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDateHash() => r'babe7bf8988b7d85142317a6ecee108a681e205f';

/// Currently selected day, shown in the left pane.

abstract class _$SelectedDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Anchor date of the visible calendar in the right pane.

@ProviderFor(CalendarAnchor)
final calendarAnchorProvider = CalendarAnchorProvider._();

/// Anchor date of the visible calendar in the right pane.
final class CalendarAnchorProvider
    extends $NotifierProvider<CalendarAnchor, DateTime> {
  /// Anchor date of the visible calendar in the right pane.
  CalendarAnchorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarAnchorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarAnchorHash();

  @$internal
  @override
  CalendarAnchor create() => CalendarAnchor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$calendarAnchorHash() => r'15bb88f814e73b1db6709bda7abbc40564b088c5';

/// Anchor date of the visible calendar in the right pane.

abstract class _$CalendarAnchor extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Active calendar view of the right pane.

@ProviderFor(CalendarViewMode)
final calendarViewModeProvider = CalendarViewModeProvider._();

/// Active calendar view of the right pane.
final class CalendarViewModeProvider
    extends $NotifierProvider<CalendarViewMode, CalendarView> {
  /// Active calendar view of the right pane.
  CalendarViewModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarViewModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarViewModeHash();

  @$internal
  @override
  CalendarViewMode create() => CalendarViewMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarView>(value),
    );
  }
}

String _$calendarViewModeHash() => r'94a51cfd396cc94d86df6688880649392bde887d';

/// Active calendar view of the right pane.

abstract class _$CalendarViewMode extends $Notifier<CalendarView> {
  CalendarView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarView, CalendarView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarView, CalendarView>,
              CalendarView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Selected tag filter; null means "all".

@ProviderFor(TagFilter)
final tagFilterProvider = TagFilterProvider._();

/// Selected tag filter; null means "all".
final class TagFilterProvider extends $NotifierProvider<TagFilter, int?> {
  /// Selected tag filter; null means "all".
  TagFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagFilterHash();

  @$internal
  @override
  TagFilter create() => TagFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$tagFilterHash() => r'b810272336dc2ef576cf3226b6ccd7cb460a5515';

/// Selected tag filter; null means "all".

abstract class _$TagFilter extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.

@ProviderFor(QuickAddRequest)
final quickAddRequestProvider = QuickAddRequestProvider._();

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.
final class QuickAddRequestProvider
    extends $NotifierProvider<QuickAddRequest, int> {
  /// Increments whenever the tray requests the quick-add dialog.
  ///
  /// Using a counter (rather than a boolean) makes the event idempotent:
  /// every tray click produces a fresh event even if the dialog was already
  /// shown and dismissed.
  QuickAddRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddRequestHash();

  @$internal
  @override
  QuickAddRequest create() => QuickAddRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$quickAddRequestHash() => r'28a888515bec4c327c19f2a25bdf2e247534c319';

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.

abstract class _$QuickAddRequest extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Index of the active tab in the narrow layout.
///
/// Hoisted into a provider so the selection survives the wide→narrow
/// layout transition (which otherwise remounts the tab widget and resets
/// the index).

@ProviderFor(HomeTab)
final homeTabProvider = HomeTabProvider._();

/// Index of the active tab in the narrow layout.
///
/// Hoisted into a provider so the selection survives the wide→narrow
/// layout transition (which otherwise remounts the tab widget and resets
/// the index).
final class HomeTabProvider extends $NotifierProvider<HomeTab, int> {
  /// Index of the active tab in the narrow layout.
  ///
  /// Hoisted into a provider so the selection survives the wide→narrow
  /// layout transition (which otherwise remounts the tab widget and resets
  /// the index).
  HomeTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTabHash();

  @$internal
  @override
  HomeTab create() => HomeTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$homeTabHash() => r'35267eb9ae3fdb2864764395985cd45389dc0661';

/// Index of the active tab in the narrow layout.
///
/// Hoisted into a provider so the selection survives the wide→narrow
/// layout transition (which otherwise remounts the tab widget and resets
/// the index).

abstract class _$HomeTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Day-keys covered by the visible calendar (week or month).

@ProviderFor(visibleDateKeys)
final visibleDateKeysProvider = VisibleDateKeysProvider._();

/// Day-keys covered by the visible calendar (week or month).

final class VisibleDateKeysProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Day-keys covered by the visible calendar (week or month).
  VisibleDateKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleDateKeysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleDateKeysHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return visibleDateKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$visibleDateKeysHash() => r'64ba5530d7921be5c05e15f8590d2e2fb350301a';
