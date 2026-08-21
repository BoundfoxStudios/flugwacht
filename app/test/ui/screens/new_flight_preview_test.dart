import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/data/lookup/route_lookup.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/ui/screens/new_flight_form.dart';
import 'package:flugwacht/ui/screens/new_flight_preview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDF',
    iataCode: 'FRA',
    name: 'Frankfurt Airport',
    latitude: 50.026402,
    longitude: 8.543130,
  ),
  destination: RouteAirport(
    icaoCode: 'KJFK',
    iataCode: 'JFK',
    name: 'John F Kennedy Airport',
    latitude: 40.639447,
    longitude: -73.779317,
  ),
);

void main() {
  late NewFlightForm form;
  late FakeRouteLookup routeLookup;
  late NewFlightPreview preview;

  void createPreview() {
    form = NewFlightForm(today: DateTime(2026, 8, 12));
    routeLookup = FakeRouteLookup(const RouteFound('DLH400', _route));
    preview = NewFlightPreview(
      form: form,
      airlineDirectory: createTestAirlineDirectory(),
      routeLookup: routeLookup,
    );
  }

  void disposePreview() {
    preview.dispose();
    form.dispose();
  }

  void enterFlightNumber(String value) =>
      form.inputFor(FlightLookupKind.flightNumber).value = value;

  test('waits for the typing to stop before looking up', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 4');
      async.elapse(const Duration(milliseconds: 300));
      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 300));

      expect(routeLookup.requests, isEmpty);

      async.elapse(const Duration(milliseconds: 100));

      expect(routeLookup.requests, [
        ['DLH400', 'GEC400'],
      ]);
      disposePreview();
    });
  });

  test('shows the found route with the winning callsign', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(
        preview.state.value,
        isA<FlightPreviewFound>()
            .having((state) => state.callsign, 'callsign', 'DLH400')
            .having((state) => state.route, 'route', _route),
      );
      disposePreview();
    });
  });

  test('shows the route as unknown when the standing data has none', () {
    fakeAsync((async) {
      createPreview();
      routeLookup.result = const RouteNotFound();

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewRouteUnknown>());
      disposePreview();
    });
  });

  test('shows the route as unknown when the lookup fails', () {
    fakeAsync((async) {
      createPreview();
      routeLookup.result = const RouteLookupFailure();

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewRouteUnknown>());
      disposePreview();
    });
  });

  test('drops a result that a newer input has outdated', () {
    fakeAsync((async) {
      createPreview();
      final pendingResult = Completer<RouteLookupResult>();
      routeLookup.pendingResult = pendingResult;

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 400));
      enterFlightNumber('LH 401');
      pendingResult.complete(const RouteFound('DLH400', _route));
      async.flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewSearching>());
      disposePreview();
    });
  });

  test('hides the card while the flight number cannot be parsed', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(routeLookup.requests, isEmpty);
      expect(preview.state.value, isA<FlightPreviewHidden>());
      disposePreview();
    });
  });

  test('hides the card outside the flight number kind', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();
      form.lookupKind.value = FlightLookupKind.registration;

      expect(preview.state.value, isA<FlightPreviewHidden>());
      disposePreview();
    });
  });

  test('searches as soon as the flight number parses', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 100));

      expect(routeLookup.requests, isEmpty);
      expect(preview.state.value, isA<FlightPreviewSearching>());
      disposePreview();
    });
  });

  test('keeps searching until the found route arrives', () {
    fakeAsync((async) {
      createPreview();
      final pendingResult = Completer<RouteLookupResult>();
      routeLookup.pendingResult = pendingResult;

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewSearching>());

      pendingResult.complete(const RouteFound('DLH400', _route));
      async.flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewFound>());
      disposePreview();
    });
  });

  test('keeps searching until the unknown route arrives', () {
    fakeAsync((async) {
      createPreview();
      final pendingResult = Completer<RouteLookupResult>();
      routeLookup.pendingResult = pendingResult;

      enterFlightNumber('LH 400');
      async
        ..elapse(const Duration(milliseconds: 400))
        ..flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewSearching>());

      pendingResult.complete(const RouteNotFound());
      async.flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewRouteUnknown>());
      disposePreview();
    });
  });

  test('ends a running search when the input is cleared', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 100));
      enterFlightNumber('');

      expect(preview.state.value, isA<FlightPreviewHidden>());
      disposePreview();
    });
  });

  test('ends a running search when the lookup kind changes', () {
    fakeAsync((async) {
      createPreview();

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 100));
      form.lookupKind.value = FlightLookupKind.hexAddress;

      expect(preview.state.value, isA<FlightPreviewHidden>());
      disposePreview();
    });
  });

  test('drops a route that an answer of the same number has outdated', () {
    fakeAsync((async) {
      createPreview();
      final stale = Completer<RouteLookupResult>();
      routeLookup.pendingResult = stale;

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 400));
      final current = Completer<RouteLookupResult>();
      routeLookup.pendingResult = current;
      enterFlightNumber('LH 40');
      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 400));

      current.complete(const RouteFound('DLH400', _route));
      async.flushMicrotasks();
      expect(preview.state.value, isA<FlightPreviewFound>());

      stale.complete(const RouteLookupFailure());
      async.flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewFound>());
      disposePreview();
    });
  });

  test('drops a route that answers after the preview is gone', () {
    fakeAsync((async) {
      createPreview();
      routeLookup.pendingResult = Completer<RouteLookupResult>();

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 400));
      disposePreview();
      routeLookup.pendingResult!.complete(const RouteFound('DLH400', _route));

      expect(async.flushMicrotasks, returnsNormally);
    });
  });

  test('drops a route that answers after the lookup kind changed', () {
    fakeAsync((async) {
      createPreview();
      routeLookup.pendingResult = Completer<RouteLookupResult>();

      enterFlightNumber('LH 400');
      async.elapse(const Duration(milliseconds: 400));
      form.lookupKind.value = FlightLookupKind.registration;
      routeLookup.pendingResult!.complete(const RouteFound('DLH400', _route));
      async.flushMicrotasks();

      expect(preview.state.value, isA<FlightPreviewHidden>());
      disposePreview();
    });
  });
}
