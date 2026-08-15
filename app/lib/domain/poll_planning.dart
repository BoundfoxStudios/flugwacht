import 'fix.dart';
import 'flight.dart';
import 'flight_day_window.dart';
import 'flight_state.dart';
import 'source_id.dart';

const livePollInterval = Duration(seconds: 5);

const searchPollInterval = Duration(seconds: 60);

bool isPollable(FlightState state) => switch (state) {
  FlightState.waiting || FlightState.live || FlightState.noSignal => true,
  FlightState.planned || FlightState.ended || FlightState.missed => false,
};

Duration pollInterval(FlightState state) =>
    state == FlightState.live ? livePollInterval : searchPollInterval;

const searchLeadTime = Duration(hours: 2);

/// The instant a flight that has never been seen may first be searched for,
/// so a daily rotation of the same callsign is not adopted at midnight.
DateTime searchStartsAt(Flight flight) {
  final window = FlightDayWindow.forDepartureDate(flight.departureDate);
  final departureTime = flight.departureTime;
  if (departureTime == null) {
    return window.start;
  }
  final departureDate = flight.departureDate;
  final anchor = DateTime(
    departureDate.year,
    departureDate.month,
    departureDate.day,
    departureTime.hour,
    departureTime.minute,
  ).subtract(searchLeadTime);
  return anchor.isBefore(window.start) ? window.start : anchor;
}

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
) => <String>{?expectedCallsign, ...callsignCandidates}.toList();

sealed class PollOutcome {
  const PollOutcome();
}

final class PollNoData extends PollOutcome {
  const PollNoData();
}

final class PollIdentityRejected extends PollOutcome {
  const PollIdentityRejected();
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

  final String hexAddress;
  final String callsign;
}

PollOutcome applyLookup({
  required Flight flight,
  required PollQuery query,
  required List<Fix> fixes,
  required FlightDayWindow window,
}) {
  final selection = _selectFix(query, fixes);
  if (selection == null) {
    return const PollNoData();
  }
  final fix = selection.fix;
  if (_rejectsIdentity(flight, query, fix)) {
    return const PollIdentityRejected();
  }
  final matchedCallsign = selection.matchedCallsign;
  return PollFixApplied(
    tracking: flight.tracking.withFix(fix, window),
    sourceId: fix.sourceId,
    trailPosition: _trailPosition(flight, fix, window),
    adoptedIdentity: matchedCallsign == null
        ? null
        : AdoptedIdentity(
            hexAddress: fix.hexAddress,
            callsign: matchedCallsign,
          ),
  );
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
  if (query is! HexAddressPollQuery ||
      flight.lookupKind != FlightLookupKind.flightNumber) {
    return false;
  }
  final callsign = _callsignOf(fix);
  return callsign != null && callsign != flight.expectedCallsign;
}

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
