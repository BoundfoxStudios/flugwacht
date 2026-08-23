import 'dart:io';

import 'package:flutter/services.dart';

import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/live_activity_state.dart';
import 'package:signals/signals.dart';

import 'live_activity_url.dart';

/// The App Group the app and the widget extension share; the plugin moves the
/// card's data through its user defaults.
const liveActivityAppGroupId = 'group.com.boundfoxstudios.apps.flugwacht';

/// What the device does with Live Activities: [unsupported] is the platform's
/// answer, [disabled] the user's — they can switch the app's activities off in
/// the system settings.
enum LiveActivityAvailability { unsupported, disabled, enabled }

/// What became of a card the app started. [unknown] is not an answer but the
/// absence of one: right after a cold start ActivityKit has not always loaded
/// its activities yet, and a card it does not mention then may well be on the
/// Lock Screen.
enum LiveActivityPresence { running, finished, unknown }

/// The seam between the app and the Live Activity plugin, so nothing above it
/// talks to the platform directly.
abstract interface class LiveActivityService {
  /// The flights whose card the user tapped.
  Stream<int> get tappedFlights;

  /// The flight whose card started the app, if one did — a tap the app was not
  /// yet running to receive.
  Future<int?> takeLaunchFlight();

  Signal<LiveActivityAvailability> get availability;

  /// Picks up what the user changed in the system settings.
  Future<void> refreshAvailability();

  /// Puts the flight's facts on its card, starting the activity when none runs
  /// under [activityId] yet.
  ///
  /// Past [staleIn] the card tells the viewer that its numbers are no longer
  /// backed by fresh data. Every put renews that window: it is the only clock
  /// the app can leave behind, because iOS renders the card once more when it
  /// runs out — the single chance a card has to stop counting towards a moment
  /// that passed while the app was closed.
  ///
  /// [relevanceScore] ranks this card against the app's other ones; the highest
  /// gets the Dynamic Island.
  Future<void> put(
    String activityId, {
    required Map<String, dynamic> data,
    required Duration staleIn,
    required double relevanceScore,
  });

  /// Takes the card away — at [dismissAt] when the user should still get to
  /// look at it, right away otherwise.
  Future<void> end(String activityId, {DateTime? dismissAt});

  /// What the system did with the activity started under [activityId]. It
  /// outlives nothing the app remembers: iOS ends a card on its own once it
  /// hits the runtime limit, and the user can swipe it away.
  Future<LiveActivityPresence> presenceOf(String activityId);
}

class PluginLiveActivityService implements LiveActivityService {
  PluginLiveActivityService._(this._plugin)
    : availability = signal(LiveActivityAvailability.unsupported);

  /// Sets the plugin up for the App Group both targets share. Live Activities
  /// are an iOS feature here (#149 parks Android), and a device that fails the
  /// setup costs the user the cards, never a stalled app.
  static Future<LiveActivityService> start() async {
    if (!Platform.isIOS) {
      return UnavailableLiveActivityService();
    }
    try {
      final plugin = LiveActivities();
      await plugin.init(
        appGroupId: liveActivityAppGroupId,
        urlScheme: liveActivityUrlScheme,
      );
      final service = PluginLiveActivityService._(plugin);
      await service.refreshAvailability();
      return service;
    } on Exception {
      return UnavailableLiveActivityService();
    }
  }

  static const _launchUrls = MethodChannel('flugwacht/launch_url');

  final LiveActivities _plugin;

  @override
  final Signal<LiveActivityAvailability> availability;

  @override
  Stream<int> get tappedFlights => _plugin
      .urlSchemeStream()
      .map((data) => flightIdFromLiveActivityUrl(data.url ?? ''))
      .where((flightId) => flightId != null)
      .cast<int>();

  /// The plugin only hears a url that reaches a running app, so a cold start
  /// is picked up natively and parked until Dart asks for it.
  @override
  Future<int?> takeLaunchFlight() async {
    final url = await _launchUrls.invokeMethod<String>('take');
    return url == null ? null : flightIdFromLiveActivityUrl(url);
  }

  @override
  Future<void> refreshAvailability() async {
    availability.value = switch ((
      await _plugin.areActivitiesSupported(),
      await _plugin.areActivitiesEnabled(),
    )) {
      (false, _) => LiveActivityAvailability.unsupported,
      (true, false) => LiveActivityAvailability.disabled,
      (true, true) => LiveActivityAvailability.enabled,
    };
  }

  @override
  Future<void> put(
    String activityId, {
    required Map<String, dynamic> data,
    required Duration staleIn,
    required double relevanceScore,
  }) async {
    await _plugin.createOrUpdateActivity(
      activityId,
      data,
      // The card belongs to the flight, not to the app run: it keeps counting
      // down while the app is closed, and the system clears it on its own.
      removeWhenAppIsKilled: false,
      iOSEnableRemoteUpdates: false,
      staleIn: staleIn,
      relevanceScore: relevanceScore,
    );
  }

  @override
  Future<void> end(String activityId, {DateTime? dismissAt}) =>
      dismissAt == null
      ? _plugin.endActivity(activityId)
      : _plugin.scheduleEnd(activityId, at: dismissAt);

  /// Asked per id on purpose: `getAllActivitiesIds` answers in ActivityKit's
  /// own identifiers, while the plugin hashes ours into the activity's
  /// attributes — the two never compare equal. `getActivityState` is the one
  /// call that takes the id the app started the card with.
  @override
  Future<LiveActivityPresence> presenceOf(String activityId) async =>
      switch (await _plugin.getActivityState(activityId)) {
        LiveActivityState.active ||
        LiveActivityState.stale => LiveActivityPresence.running,
        LiveActivityState.ended ||
        LiveActivityState.dismissed => LiveActivityPresence.finished,
        LiveActivityState.unknown || null => LiveActivityPresence.unknown,
      };
}

/// What a device without Live Activities gets: every call is a no-op, so
/// nothing above has to ask whether the platform can do this.
class UnavailableLiveActivityService implements LiveActivityService {
  @override
  final availability = signal(LiveActivityAvailability.unsupported);

  @override
  Stream<int> get tappedFlights => const Stream.empty();

  @override
  Future<int?> takeLaunchFlight() async => null;

  @override
  Future<void> refreshAvailability() async {}

  @override
  Future<void> put(
    String activityId, {
    required Map<String, dynamic> data,
    required Duration staleIn,
    required double relevanceScore,
  }) async {}

  @override
  Future<void> end(String activityId, {DateTime? dismissAt}) async {}

  @override
  Future<LiveActivityPresence> presenceOf(String activityId) async =>
      LiveActivityPresence.unknown;
}
