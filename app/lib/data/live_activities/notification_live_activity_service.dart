import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signals/signals.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../../domain/flight.dart';
import '../../domain/flight_card.dart';
import '../notifications/notification_ids.dart';
import 'live_activity_id.dart';
import 'live_activity_payload.dart';
import 'live_activity_service.dart';

/// What a card says; built where the localizations live, because nothing down
/// here knows them.
typedef FlightCardText = ({String title, String body});
typedef FlightCardCopy = FlightCardText Function(FlightCard card);

/// The card on Android: an ongoing notification whose countdown the system
/// draws itself, so it keeps running while the app is closed.
///
/// Android has no counterpart to the stale date iOS redraws a card at, so the
/// same effect is scheduled by hand: a second notification under the card's own
/// id, due the moment the numbers stop being true, replaces it with one that no
/// longer counts.
class NotificationLiveActivityService implements LiveActivityService {
  NotificationLiveActivityService._(
    this._plugin,
    this._copy,
    this._channelName,
    this.clock,
  ) : availability = signal(LiveActivityAvailability.unsupported);

  static const cardChannelId = 'flight_card';

  /// Creates the card's own channel, so the cards can be switched off without
  /// costing the flight its other notifications. Called after the notification
  /// service has initialized the plugin, whose single instance it shares.
  static Future<LiveActivityService> start({
    required FlightCardCopy copy,
    required String channelName,
    required String channelDescription,
    DateTime Function() clock = DateTime.now,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              cardChannelId,
              channelName,
              description: channelDescription,
              // A card is there to be looked at, not to interrupt.
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
            ),
          );
      final service = NotificationLiveActivityService._(
        plugin,
        copy,
        channelName,
        clock,
      );
      await service.refreshAvailability();
      return service;
    } on Exception {
      return UnavailableLiveActivityService();
    }
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final FlightCardCopy _copy;
  final String _channelName;
  final DateTime Function() clock;

  /// What a card last showed, so it can go up again with an expiry once the
  /// flight is done. Only this run's cards are in here, which is enough: a card
  /// is always written once more right before it ends.
  final _lastPut = <int, ({FlightCardText text, FlightCard card})>{};

  @override
  final Signal<LiveActivityAvailability> availability;

  /// A tap on a card reaches the app through the notification service, which
  /// receives every notification's payload, cards included.
  @override
  Stream<int> get tappedFlights => const Stream.empty();

  @override
  Future<int?> takeLaunchFlight() async => null;

  @override
  Future<void> refreshAvailability() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      availability.value = LiveActivityAvailability.unsupported;
      return;
    }
    final isEnabled = await android.areNotificationsEnabled() ?? false;
    availability.value = isEnabled && await _isChannelOn(android)
        ? LiveActivityAvailability.enabled
        : LiveActivityAvailability.disabled;
  }

  @override
  Future<void> put(
    String activityId, {
    required Flight flight,
    required DateTime now,
  }) async {
    final card = flightCardOf(flight, now);
    final text = _copy(card);
    _lastPut[flight.id] = (text: text, card: card);
    await _plugin.show(
      id: flightCardIdOf(flight.id),
      title: text.title,
      body: text.body,
      notificationDetails: _detailsOf(card),
      payload: '${flight.id}',
    );
    await _scheduleStaleUpdate(flight, card, now);
  }

  @override
  Future<void> end(String activityId, {DateTime? dismissAt}) async {
    final flightId = flightIdFromLiveActivityId(activityId);
    if (flightId == null) {
      return;
    }
    final last = _lastPut.remove(flightId);
    // Cancelled first either way: it takes the scheduled stale update with it,
    // which would otherwise bring a card the flight is done with back up.
    await _plugin.cancel(id: flightCardIdOf(flightId));
    if (dismissAt == null || last == null) {
      return;
    }
    await _plugin.show(
      id: flightCardIdOf(flightId),
      title: last.text.title,
      body: last.text.body,
      notificationDetails: _detailsOf(last.card, dismissAt: dismissAt),
      payload: '$flightId',
    );
  }

  /// Android never ends a card on its own, so the only way one goes missing is
  /// the user swiping it away.
  @override
  Future<LiveActivityPresence> presenceOf(String activityId) async {
    final flightId = flightIdFromLiveActivityId(activityId);
    if (flightId == null) {
      return LiveActivityPresence.unknown;
    }
    final cardId = flightCardIdOf(flightId);
    final active = await _plugin.getActiveNotifications();
    return active.any((notification) => notification.id == cardId)
        ? LiveActivityPresence.running
        : LiveActivityPresence.finished;
  }

  Future<bool> _isChannelOn(
    AndroidFlutterLocalNotificationsPlugin android,
  ) async {
    final channels = await android.getNotificationChannels();
    // A device that does not answer at all predates channels, where nothing
    // below the app's own switch can be off.
    return channels?.any(
          (channel) =>
              channel.id == cardChannelId &&
              channel.importance != Importance.none,
        ) ??
        true;
  }

  /// The card is replaced in place once its numbers stop being true, and only
  /// while something is still counting: without a countdown there is nothing
  /// that could keep running past the moment it counted to.
  Future<void> _scheduleStaleUpdate(
    Flight flight,
    FlightCard card,
    DateTime now,
  ) async {
    if (card.countdown == null) {
      return;
    }
    final staleAt = now.add(liveActivityStaleIn(flight, now));
    // Android refuses an alarm in the past, and a moment already gone needs no
    // update: the card just went up carrying exactly that.
    if (!staleAt.isAfter(clock())) {
      return;
    }
    final staleCard = flightCardOf(flight, staleAt);
    final staleText = _copy(staleCard);
    await _plugin.zonedSchedule(
      id: flightCardIdOf(flight.id),
      title: staleText.title,
      body: staleText.body,
      scheduledDate: timezone.TZDateTime.from(staleAt, timezone.UTC),
      notificationDetails: _detailsOf(staleCard),
      payload: '${flight.id}',
      // A card going quiet is not worth an exact alarm and the permission it
      // would cost; a few minutes late costs the reader nothing.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// A [dismissAt] turns the card into one the flight is done with: Android
  /// takes it away once the timeout runs out, which is the closest it has to a
  /// scheduled dismissal, and it stops being ongoing so it can be swiped away.
  NotificationDetails _detailsOf(FlightCard card, {DateTime? dismissAt}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          cardChannelId,
          _channelName,
          category: AndroidNotificationCategory.progress,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: dismissAt == null,
          autoCancel: false,
          silent: true,
          onlyAlertOnce: true,
          showWhen: card.countdown != null,
          when: card.countdown?.at.millisecondsSinceEpoch,
          usesChronometer: card.countdown != null,
          chronometerCountDown: card.countdown != null,
          showProgress: card.progressPercent != null,
          maxProgress: 100,
          progress: card.progressPercent ?? 0,
          timeoutAfter: dismissAt
              ?.difference(clock())
              .inMilliseconds
              .clamp(1, _longestDismissal.inMilliseconds),
        ),
      );
}

const _longestDismissal = Duration(hours: 12);
