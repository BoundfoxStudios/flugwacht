import 'arrival_estimate.dart';
import 'departure_time.dart';
import 'fix.dart';
import 'flight.dart';
import 'flight_day_window.dart';
import 'flight_number.dart';
import 'flight_state.dart';
import 'source_id.dart';

const livePollInterval = Duration(seconds: 5);

const searchPollInterval = Duration(seconds: 60);

/// Wider than the search interval, so an evening departure is not asked for
/// every minute from midnight on.
const preDepartureSearchInterval = Duration(minutes: 5);

const originContactRadiusKilometers = 25.0;

bool isPollable(FlightState state) => switch (state) {
  FlightState.waiting || FlightState.live || FlightState.noSignal => true,
  FlightState.planned || FlightState.ended || FlightState.missed => false,
};

Duration pollInterval(Flight flight, FlightState state, DateTime now) {
  if (awaitsDepartureContact(flight, now)) {
    return preDepartureSearchInterval;
  }
  return state == FlightState.live ? livePollInterval : searchPollInterval;
}

const searchLeadTime = Duration(hours: 2);

/// The instant from which an airborne aircraft may be adopted as a flight's
/// first contact, so a daily rotation of the same callsign is not adopted at
/// midnight.
DateTime airborneContactStartsAt(Flight flight) {
  final window = FlightDayWindow.forDepartureDate(flight.departureDate);
  final departureInstant = departureInstantOf(flight);
  if (departureInstant == null) {
    return window.start;
  }
  final anchor = departureInstant.subtract(searchLeadTime);
  return anchor.isBefore(window.start) ? window.start : anchor;
}

bool awaitsDepartureContact(Flight flight, DateTime now) =>
    now.isBefore(airborneContactStartsAt(flight));

sealed class PollQuery {
  const PollQuery();
}

final class HexAddressPollQuery extends PollQuery {
  const HexAddressPollQuery(this.hexAddress);

  final String hexAddress;
}

final class RegistrationPollQuery extends PollQuery {
  const RegistrationPollQuery(this.registration);

  final String registration;
}

final class CallsignSearchPollQuery extends PollQuery {
  const CallsignSearchPollQuery(this.candidates);

  final List<String> candidates;
}

PollQuery planPollQuery(Flight flight, List<String> callsignCandidates) =>
    switch (flight.lookupKind) {
      FlightLookupKind.hexAddress => HexAddressPollQuery(flight.lookupValue),
      FlightLookupKind.registration => RegistrationPollQuery(
        flight.lookupValue,
      ),
      FlightLookupKind.flightNumber => switch (flight.hexAddress) {
        final String hexAddress => HexAddressPollQuery(hexAddress),
        null => CallsignSearchPollQuery(
          _orderedCandidates(flight.expectedCallsign, callsignCandidates),
        ),
      },
    };

List<String> _orderedCandidates(
  String? expectedCallsign,
  List<String> callsignCandidates,
) => <String>{
  ..._callsignForms(expectedCallsign),
  ...callsignCandidates,
}.toList();

/// The known callsign in both forms: it is stored the way the standing data
/// lists it, which strips the leading zeros an aircraft transmits.
Iterable<String> _callsignForms(String? callsign) sync* {
  if (callsign == null) {
    return;
  }
  yield callsign;
  final wireForm = FlightNumber.tryParse(callsign)?.wireForm;
  if (wireForm != null && wireForm != callsign) {
    yield wireForm;
  }
}

sealed class PollOutcome {
  const PollOutcome();
}

final class PollNoData extends PollOutcome {
  const PollNoData();
}

final class PollIdentityRejected extends PollOutcome {
  const PollIdentityRejected();
}

final class PollAwaitsDeparture extends PollOutcome {
  const PollAwaitsDeparture();
}

/// An aircraft still standing at its gate is not a flight under way: it says
/// who it is, it does not say where the flight is.
final class PollIdentityAdopted extends PollOutcome {
  const PollIdentityAdopted(this.identity);

  final AdoptedIdentity identity;
}

/// The entered leg cannot land before its scheduled departure, so a landing
/// before it exposes the tracked contact as the airframe's earlier rotation:
/// forget it and search again.
final class PollAdoptionDisproved extends PollOutcome {
  const PollAdoptionDisproved();
}

final class PollFixApplied extends PollOutcome {
  const PollFixApplied({
    required this.tracking,
    required this.sourceId,
    this.trailPosition,
    this.adoptedIdentity,
  });

  final FlightTracking tracking;
  final SourceId sourceId;
  final FixPosition? trailPosition;
  final AdoptedIdentity? adoptedIdentity;
}

final class AdoptedIdentity {
  const AdoptedIdentity({required this.hexAddress, required this.callsign});

  /// Null keeps the hex address the flight already stores.
  final String? hexAddress;

  final String callsign;
}

PollOutcome applyLookup({
  required Flight flight,
  required PollQuery query,
  required List<Fix> fixes,
  required FlightDayWindow window,
  required DateTime now,
}) {
  final selection = _selectFix(query, fixes);
  if (selection == null) {
    return const PollNoData();
  }
  final fix = selection.fix;
  if (_rejectsIdentity(flight, query, fix)) {
    return const PollIdentityRejected();
  }
  if (awaitsDepartureContact(flight, now)) {
    final identity = _standsAtItsOrigin(flight, fix)
        ? _adoptedIdentity(flight, query, selection, window)
        : null;
    return identity == null
        ? const PollAwaitsDeparture()
        : PollIdentityAdopted(identity);
  }
  if (_disprovesAdoption(flight, fix)) {
    return const PollAdoptionDisproved();
  }
  return PollFixApplied(
    tracking: flight.tracking.withFix(fix, window),
    sourceId: fix.sourceId,
    trailPosition: _trailPosition(flight, fix, window),
    adoptedIdentity: _adoptedIdentity(flight, query, selection, window),
  );
}

bool _disprovesAdoption(Flight flight, Fix fix) {
  if (flight.lookupKind != FlightLookupKind.registration &&
      flight.lookupKind != FlightLookupKind.hexAddress) {
    return false;
  }
  final position = fix.position;
  if (!flight.tracking.hasBeenAirborne || position?.onGround != true) {
    return false;
  }
  final departureInstant = departureInstantOf(flight);
  return departureInstant != null &&
      position!.timestamp.isBefore(departureInstant);
}

AdoptedIdentity? _adoptedIdentity(
  Flight flight,
  PollQuery query,
  _FixSelection selection,
  FlightDayWindow window,
) {
  final matchedCallsign = selection.matchedCallsign;
  if (matchedCallsign != null) {
    return AdoptedIdentity(
      hexAddress: selection.fix.hexAddress,
      callsign: matchedCallsign,
    );
  }
  final position = selection.fix.position;
  // A standing airframe can still wear the callsign of the leg it just arrived
  // on, and an answer that neither reports its altitude nor a position from
  // this flight day proves nothing either, so only a fix that positively
  // reports flight names this one.
  if (!_pinsFirstCallsign(flight, query) ||
      flight.expectedCallsign != null ||
      position == null ||
      position.onGround != false ||
      position.timestamp.isBefore(window.start)) {
    return null;
  }
  final callsign = _callsignOf(selection.fix);
  return callsign == null
      ? null
      : AdoptedIdentity(hexAddress: null, callsign: callsign);
}

class _FixSelection {
  const _FixSelection(this.fix, [this.matchedCallsign]);

  final Fix fix;
  final String? matchedCallsign;
}

_FixSelection? _selectFix(PollQuery query, List<Fix> fixes) {
  switch (query) {
    case CallsignSearchPollQuery(:final candidates):
      for (final candidate in candidates) {
        final matching = fixes
            .where((fix) => _callsignOf(fix) == candidate)
            .toList();
        if (matching.isNotEmpty) {
          return _FixSelection(_preferringPosition(matching), candidate);
        }
      }
      return null;
    case HexAddressPollQuery() || RegistrationPollQuery():
      return fixes.isEmpty ? null : _FixSelection(_preferringPosition(fixes));
  }
}

Fix _preferringPosition(List<Fix> fixes) =>
    fixes.firstWhere((fix) => fix.position != null, orElse: () => fixes.first);

bool _rejectsIdentity(Flight flight, PollQuery query, Fix fix) {
  final callsign = _callsignOf(fix);
  if (callsign == null || callsign == flight.expectedCallsign) {
    return false;
  }
  if (_pinsFirstCallsign(flight, query)) {
    return flight.expectedCallsign != null;
  }
  return query is HexAddressPollQuery &&
      flight.lookupKind == FlightLookupKind.flightNumber;
}

/// Yesterday's leg of a daily callsign is still airborne at that hour, so
/// before the anchor only an aircraft standing at the origin can be the flight
/// the user entered. An entered airframe has no route and therefore nothing to
/// gain here: its identity is the query.
bool _standsAtItsOrigin(Flight flight, Fix fix) {
  final origin = flight.route?.origin;
  final position = fix.position;
  if (origin == null || position == null || position.onGround != true) {
    return false;
  }
  return greatCircleDistanceKilometers(
        position.latitude,
        position.longitude,
        origin.latitude,
        origin.longitude,
      ) <=
      originContactRadiusKilometers;
}

bool _pinsFirstCallsign(Flight flight, PollQuery query) =>
    (query is HexAddressPollQuery || query is RegistrationPollQuery) &&
    (flight.lookupKind == FlightLookupKind.registration ||
        flight.lookupKind == FlightLookupKind.hexAddress);

FixPosition? _trailPosition(Flight flight, Fix fix, FlightDayWindow window) {
  final position = fix.position;
  if (position == null || position.timestamp.isBefore(window.start)) {
    return null;
  }
  final latestPosition = flight.tracking.latestPosition;
  return latestPosition == null ||
          position.timestamp.isAfter(latestPosition.timestamp)
      ? position
      : null;
}

String? _callsignOf(Fix fix) {
  final callsign = fix.callsign?.trim();
  return callsign == null || callsign.isEmpty ? null : callsign;
}
