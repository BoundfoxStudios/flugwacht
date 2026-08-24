import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/live_activities/notification_live_activity_service.dart';
import '../../../domain/flight.dart';
import '../../../domain/flight_card.dart';
import '../../../domain/flight_state.dart';
import '../../../l10n/app_localizations.g.dart';
import 'flight_labels.dart';

/// Everything the app says about a flight's card, in the words of the platform
/// the card runs on.
///
/// Apple's "Live Activity" and "Lock Screen" are its own vocabulary and mean
/// nothing on Android, which in turn has no established name for what it shows.
/// So iOS keeps Apple's terms and Android names the effect instead of a
/// feature. Google's "Live Updates" would be the wrong promise: that is the
/// promoted surface the app deliberately does not build.
bool get _isApple => defaultTargetPlatform == TargetPlatform.iOS;

String liveActivityArmLabel(AppLocalizations localizations) => _isApple
    ? localizations.liveActivityArmLabel
    : localizations.lockScreenArmLabel;

String liveActivityDisabledHint(AppLocalizations localizations) => _isApple
    ? localizations.liveActivityDisabledHint
    : localizations.lockScreenDisabledHint;

String liveActivitySettingsHint(AppLocalizations localizations) => _isApple
    ? localizations.settingsLiveActivityHint
    : localizations.settingsLockScreenHint;

/// What the flight-day reminder says; the title names the offer, the body the
/// flight the way every screen does.
({String title, String body}) flightLiveActivityReminderText(
  AppLocalizations localizations,
  Flight flight,
) {
  final title = flightTitle(localizations, flight);
  return _isApple
      ? (
          title: localizations.liveActivityReminderTitle,
          body: localizations.liveActivityReminderBody(title),
        )
      : (
          title: localizations.lockScreenReminderTitle,
          body: localizations.lockScreenReminderBody(title),
        );
}

/// What a card says. The countdown is not in here: the system draws it from the
/// moment the card carries, which is the whole point of letting it.
FlightCardText flightCardText(AppLocalizations localizations, FlightCard card) {
  final note = card.note;
  final route = card.route;
  final status = _cardStatus(localizations, card);
  return (
    title: note == null
        ? card.designator
        : localizations.flightTitleWithNote(card.designator, note),
    body: route == null
        ? status
        : localizations.flightRowSubtitle(
            localizations.flightRoute(route.origin, route.destination),
            status,
          ),
  );
}

/// What the card says about the flight beside its route: the nearest fact it
/// has, falling back to the state the app would name anywhere else.
String _cardStatus(AppLocalizations localizations, FlightCard card) {
  if (card.hasProbablyLanded) {
    return localizations.lockScreenCardProbablyLanded;
  }
  if (card.landedAt case final landedAt?) {
    return localizations.lockScreenCardLanded(
      _formatTime(localizations, landedAt),
    );
  }
  if (card.arrivesAt case final arrivesAt?) {
    final time = _formatTime(localizations, arrivesAt);
    return card.isArrivalUncertain
        ? localizations.lockScreenCardArrivalUncertain(time)
        : localizations.lockScreenCardArrival(time);
  }
  return switch (card.state) {
    FlightState.waiting => localizations.flightRowWaitingForSignal,
    FlightState.planned => localizations.flightStatePlanned,
    FlightState.live => localizations.flightStateLive,
    FlightState.noSignal => localizations.flightStateNoSignal,
    FlightState.ended || FlightState.missed => localizations.flightStateEnded,
  };
}

String _formatTime(AppLocalizations localizations, DateTime instant) =>
    DateFormat(
      localizations.flightArrivalTimeFormat,
      localizations.localeName,
    ).format(instant.toLocal());
