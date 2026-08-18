import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/ui/map_selection.dart';
import 'package:flugwacht/ui/screens/map_flights.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

const _departureDate = CalendarDate(2026, 8, 12);
final _window = FlightDayWindow.forDepartureDate(_departureDate);
final _now = _window.start.add(const Duration(hours: 4));

Flight _airborneFlight(int id, {Duration positionAge = Duration.zero}) =>
    Flight(
      id: id,
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH40$id',
      departureDate: _departureDate,
      tracking: FlightTracking(
        latestPosition: FixPosition(
          latitude: 48.5,
          longitude: -20,
          timestamp: _now.subtract(positionAge),
        ),
        hasBeenAirborne: true,
      ),
    );

const _waitingFlight = Flight(
  id: 9,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH999',
  departureDate: _departureDate,
);

void _withMapFlights(
  void Function(FakeAsync async, FakeFlightRepository repository, MapFlights)
  body,
) => fakeAsync((async) {
  final repository = FakeFlightRepository();
  final selection = MapSelection();
  final mapFlights = MapFlights(
    repository: repository,
    selection: selection,
    clock: () => _now,
  );
  body(async, repository, mapFlights);
  mapFlights.dispose();
  selection.dispose();
  repository.dispose();
});

void main() {
  group('the flights on the map', () {
    test('are the ones that have a position', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([
          _airborneFlight(1),
          _waitingFlight,
          _airborneFlight(2, positionAge: const Duration(hours: 1)),
        ]);
        async.flushMicrotasks();

        expect(mapFlights.flights.value.map((entry) => entry.flight.id), [
          1,
          2,
        ]);
      });
    });

    test('start out with the first one selected', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();

        expect(mapFlights.selectedId.value, 1);
        expect(mapFlights.selected.value?.flight.id, 1);
      });
    });

    test('have no selection while none of them qualifies', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([_waitingFlight]);
        async.flushMicrotasks();

        expect(mapFlights.flights.value, isEmpty);
        expect(mapFlights.selectedId.value, isNull);
        expect(mapFlights.selected.value, isNull);
      });
    });

    test('hand the selection on when the selected flight leaves', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([
          _airborneFlight(1),
          _airborneFlight(2),
          _airborneFlight(3),
        ]);
        async.flushMicrotasks();
        mapFlights.selectedId.value = 2;

        repository.emit([_airborneFlight(1), _airborneFlight(3)]);
        async.flushMicrotasks();

        expect(mapFlights.selectedId.value, 3);
      });
    });
  });

  group('a requested flight', () {
    test('takes the selection once it is on the map', () {
      _withMapFlights((async, repository, mapFlights) {
        mapFlights.selection.requestedFlightId.value = 2;

        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();

        expect(mapFlights.selectedId.value, 2);
        expect(mapFlights.selection.requestedFlightId.value, isNull);
      });
    });

    test('waits instead of settling for another flight', () {
      _withMapFlights((async, repository, mapFlights) {
        mapFlights.selection.requestedFlightId.value = 2;

        repository.emit([_airborneFlight(1)]);
        async.flushMicrotasks();
        expect(mapFlights.selectedId.value, 1);
        expect(mapFlights.selection.requestedFlightId.value, 2);

        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();

        expect(mapFlights.selectedId.value, 2);
      });
    });

    test('leaves the choices made after it alone', () {
      _withMapFlights((async, repository, mapFlights) {
        mapFlights.selection.requestedFlightId.value = 2;
        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();

        mapFlights.selectedId.value = 1;
        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();

        expect(mapFlights.selectedId.value, 1);
      });
    });
  });

  group('the trail', () {
    test('follows the selected flight', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();
        expect(repository.watchedTrails, [1]);

        mapFlights.selectedId.value = 2;
        async.flushMicrotasks();

        expect(repository.watchedTrails, [1, 2]);
      });
    });

    test('empties out until the new selection has emitted', () {
      _withMapFlights((async, repository, mapFlights) {
        repository.emit([_airborneFlight(1), _airborneFlight(2)]);
        async.flushMicrotasks();
        repository.emitTrail([
          TrailPoint(
            timestamp: _now,
            latitude: 48,
            longitude: -20,
            sourceId: SourceId.adsblol,
          ),
        ]);
        async.flushMicrotasks();
        expect(mapFlights.trail.value, hasLength(1));

        mapFlights.selectedId.value = 2;
        async.flushMicrotasks();

        expect(mapFlights.trail.value, isEmpty);
      });
    });
  });

  group('the selection fallback', () {
    test('keeps a flight that is still on the map', () {
      expect(
        nextSelectedFlightId(
          previousIds: const [1, 2, 3],
          currentIds: const [3, 2, 1],
          selectedId: 2,
        ),
        2,
      );
    });

    test('takes the flight that moved into the free index', () {
      expect(
        nextSelectedFlightId(
          previousIds: const [1, 2, 3],
          currentIds: const [1, 3],
          selectedId: 2,
        ),
        3,
      );
    });

    test('clamps to the last flight', () {
      expect(
        nextSelectedFlightId(
          previousIds: const [1, 2, 3],
          currentIds: const [1, 2],
          selectedId: 3,
        ),
        2,
      );
    });

    test('takes the first flight when nothing was selected', () {
      expect(
        nextSelectedFlightId(
          previousIds: const [],
          currentIds: const [4, 5],
          selectedId: null,
        ),
        4,
      );
    });

    test('has nothing to select on an empty map', () {
      expect(
        nextSelectedFlightId(
          previousIds: const [1],
          currentIds: const [],
          selectedId: 1,
        ),
        isNull,
      );
    });
  });
}
