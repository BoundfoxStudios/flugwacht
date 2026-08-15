import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/ui/screens/flight_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

void main() {
  const departureDate = CalendarDate(2026, 8, 12);
  final window = FlightDayWindow.forDepartureDate(departureDate);

  const flight = Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH400',
    departureDate: departureDate,
  );

  test('has no sections until the repository emits', () {
    fakeAsync((async) {
      final repository = FakeFlightRepository();
      final list = FlightList(
        repository: repository,
        clock: () => window.start,
      );

      async.flushMicrotasks();

      expect(list.sections.value, isNull);
      list.dispose();
      repository.dispose();
    });
  });

  test(
    're-derives the flight state every minute without a repository event',
    () {
      fakeAsync((async) {
        var now = window.start.subtract(const Duration(minutes: 1));
        final repository = FakeFlightRepository();
        final list = FlightList(repository: repository, clock: () => now);
        repository.emit([flight]);
        async.flushMicrotasks();
        expect(list.sections.value?.planned, hasLength(1));

        now = window.start;
        async.elapse(const Duration(minutes: 1));

        expect(list.sections.value?.planned, isEmpty);
        expect(list.sections.value?.waiting, hasLength(1));
        list.dispose();
        repository.dispose();
      });
    },
  );

  test('asks the repository to purge expired flights on every tick', () {
    fakeAsync((async) {
      final now = window.start;
      final repository = FakeFlightRepository();
      final list = FlightList(repository: repository, clock: () => now);

      async.elapse(const Duration(minutes: 3));

      expect(repository.expiryChecks, [now, now, now]);
      list.dispose();
      repository.dispose();
    });
  });

  test('stops ticking once disposed', () {
    fakeAsync((async) {
      final repository = FakeFlightRepository();
      FlightList(repository: repository, clock: () => window.start).dispose();

      async.elapse(const Duration(minutes: 3));

      expect(repository.expiryChecks, isEmpty);
      repository.dispose();
    });
  });
}
