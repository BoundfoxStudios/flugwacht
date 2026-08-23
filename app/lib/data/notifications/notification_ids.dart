import '../../domain/flight_notification.dart';

/// One slot per notification a flight can have: its own moments, the flight-day
/// reminder behind them, and the card that shows the running flight.
///
/// Shared so the card and the notifications can never claim the same id, and so
/// either can be replaced and cancelled without any bookkeeping.
final _reminderSlot = FlightNotification.values.length;
final _cardSlot = _reminderSlot + 1;
final _idsPerFlight = _cardSlot + 1;

int notificationIdOf(FlightNotification kind, int flightId) =>
    flightId * _idsPerFlight + kind.index;

int liveActivityReminderIdOf(int flightId) =>
    flightId * _idsPerFlight + _reminderSlot;

/// The card and the update that lets it go stale share an id on purpose: the
/// scheduled one is meant to replace the card in place.
int flightCardIdOf(int flightId) => flightId * _idsPerFlight + _cardSlot;
