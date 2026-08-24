import 'package:flugwacht/data/lookup/route_lookup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _base =
    'https://raw.githubusercontent.com/vradarserver/standing-data/main';

const _routeHeader = 'Callsign,Code,Number,AirlineCode,AirportCodes\n';
const _airportHeader =
    'Code,Name,ICAO,IATA,Location,CountryISO2,Latitude,Longitude,'
    'AltitudeFeet\n';

const _dlhRoutes = '${_routeHeader}DLH400,DLH,400,DLH,EDDF-KJFK\n';
const _edAirports =
    '$_airportHeader'
    'EDDF,Frankfurt Airport,EDDF,FRA,Frankfurt-am-Main,DE,50.026402,8.543130,364\n'
    'EDDM,Munich Airport,EDDM,MUC,Munich,DE,48.353783,11.786086,1487\n';
const _kjAirports =
    '$_airportHeader'
    'KJFK,John F Kennedy Airport,KJFK,JFK,New York,US,40.639447,-73.779317,13\n';

typedef _Files = Map<String, String>;

http.Client _clientServing(_Files files, {List<String>? requested}) =>
    MockClient((request) async {
      requested?.add(request.url.toString());
      final body = files[request.url.toString()];
      return body == null
          ? http.Response('', 404)
          : http.Response(
              body,
              200,
              headers: {'content-type': 'text/plain; charset=utf-8'},
            );
    });

/// Condor's route file, where the airline markets a number of its own: the
/// tests below only vary the rows it carries.
RouteLookup _lookupServingCondor(String routeRows) => RouteLookup(
  client: _clientServing({
    '$_base/routes/schema-01/C/CFG-all.csv': '$_routeHeader$routeRows',
    '$_base/airports/schema-01/E/ED.csv': _edAirports,
    '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
  }),
);

void main() {
  test(
    'requests the all-routes file and the airport files by prefix',
    () async {
      final requested = <String>[];
      final lookup = RouteLookup(
        client: _clientServing({
          '$_base/routes/schema-01/D/DLH-all.csv': _dlhRoutes,
          '$_base/airports/schema-01/E/ED.csv': _edAirports,
          '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
        }, requested: requested),
      );

      await lookup.lookup(const ['DLH400']);

      expect(requested, [
        '$_base/routes/schema-01/D/DLH-all.csv',
        '$_base/airports/schema-01/E/ED.csv',
        '$_base/airports/schema-01/K/KJ.csv',
      ]);
    },
  );

  test('resolves a route with both airports fully populated', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv': _dlhRoutes,
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
        '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
      }),
    );

    final result = await lookup.lookup(const ['DLH400']);

    expect(result, isA<RouteFound>());
    final found = result as RouteFound;
    expect(found.callsign, 'DLH400');
    expect(found.route.origin.icaoCode, 'EDDF');
    expect(found.route.origin.iataCode, 'FRA');
    expect(found.route.origin.name, 'Frankfurt Airport');
    expect(found.route.origin.location, 'Frankfurt-am-Main');
    expect(found.route.origin.latitude, 50.026402);
    expect(found.route.origin.longitude, 8.543130);
    expect(found.route.destination.icaoCode, 'KJFK');
    expect(found.route.destination.iataCode, 'JFK');
    expect(found.route.destination.latitude, 40.639447);
    expect(found.route.destination.longitude, -73.779317);
  });

  test(
    'falls back to the split route file when the all file is missing',
    () async {
      final requested = <String>[];
      final lookup = RouteLookup(
        client: _clientServing({
          '$_base/routes/schema-01/E/EZY-1.csv':
              '${_routeHeader}EZY1009,EZY,1009,EZY,EDDF-EDDM\n',
          '$_base/airports/schema-01/E/ED.csv': _edAirports,
        }, requested: requested),
      );

      final result = await lookup.lookup(const ['EZY1009']);

      expect(result, isA<RouteFound>());
      expect(requested.take(2), [
        '$_base/routes/schema-01/E/EZY-all.csv',
        '$_base/routes/schema-01/E/EZY-1.csv',
      ]);
    },
  );

  test('requests a shared airport file once', () async {
    final requested = <String>[];
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH900,DLH,900,DLH,EDDF-EDDM\n',
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
      }, requested: requested),
    );

    await lookup.lookup(const ['DLH900']);

    expect(requested.where((url) => url.contains('/airports/')).length, 1);
  });

  test('maps a multi leg chain to the first and last airport', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH500,DLH,500,DLH,EDDM-EDDF-KJFK\n',
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
        '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
      }),
    );

    final result = await lookup.lookup(const ['DLH500']);

    expect((result as RouteFound).route.origin.icaoCode, 'EDDM');
    expect(result.route.destination.icaoCode, 'KJFK');
  });

  test('reports not found for a chain ending where it started', () async {
    final requested = <String>[];
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH500,DLH,500,DLH,EDDM-EDDF-KJFK-EDDM\n',
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
        '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
      }, requested: requested),
    );

    expect(await lookup.lookup(const ['DLH500']), isA<RouteNotFound>());
    expect(requested.where((url) => url.contains('/airports/')), isEmpty);
  });

  test('reports not found for a row naming one airport twice', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH500,DLH,500,DLH,EDDF-EDDF\n',
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
      }),
    );

    expect(await lookup.lookup(const ['DLH500']), isA<RouteNotFound>());
  });

  test('reports not found for a row naming a single airport', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH500,DLH,500,DLH,EDDF\n',
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
      }),
    );

    expect(await lookup.lookup(const ['DLH500']), isA<RouteNotFound>());
  });

  test(
    'tries the candidates in order and keeps the first with a route',
    () async {
      final lookup = RouteLookup(
        client: _clientServing({
          '$_base/routes/schema-01/D/DLH-all.csv': _routeHeader,
          '$_base/routes/schema-01/G/GEC-all.csv':
              '${_routeHeader}GEC400,GEC,400,GEC,EDDF-KJFK\n',
          '$_base/airports/schema-01/E/ED.csv': _edAirports,
          '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
        }),
      );

      final result = await lookup.lookup(const ['DLH400', 'GEC400']);

      expect((result as RouteFound).callsign, 'GEC400');
    },
  );

  test('answers with the callsign a marketed number is flown under', () async {
    final lookup = _lookupServingCondor(
      'CFG16,CFG,16,CFG,EDDF-KJFK\n'
      'CFG2016,CFG,2016,CFG,EDDF-KJFK\n',
    );

    final result = await lookup.lookup(const ['CFG2016']);

    expect((result as RouteFound).callsign, 'CFG16');
    expect(result.route.destination.icaoCode, 'KJFK');
  });

  test('keeps the marketed callsign when the shorter number flies '
      'elsewhere', () async {
    final lookup = _lookupServingCondor(
      'CFG16,CFG,16,CFG,EDDF-EDDM\n'
      'CFG2016,CFG,2016,CFG,EDDF-KJFK\n',
    );

    final result = await lookup.lookup(const ['CFG2016']);

    expect((result as RouteFound).callsign, 'CFG2016');
  });

  test(
    'keeps the marketed callsign when a single digit is left over',
    () async {
      final lookup = _lookupServingCondor(
        'CFG2,CFG,2,CFG,EDDF-KJFK\n'
        'CFG1002,CFG,1002,CFG,EDDF-KJFK\n',
      );

      final result = await lookup.lookup(const ['CFG1002']);

      expect((result as RouteFound).callsign, 'CFG1002');
    },
  );

  test('reads only a number of the full width as a marketed one', () async {
    final lookup = _lookupServingCondor(
      'CFG16,CFG,16,CFG,EDDF-KJFK\n'
      'CFG216,CFG,216,CFG,EDDF-KJFK\n',
    );

    final result = await lookup.lookup(const ['CFG216']);

    expect((result as RouteFound).callsign, 'CFG216');
  });

  test('reports a missing iata code as null', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv':
            '${_routeHeader}DLH700,DLH,700,DLH,EDAB-EDDF\n',
        '$_base/airports/schema-01/E/ED.csv':
            '$_edAirports'
            'EDAB,Bautzen Airport,EDAB,,Bautzen,DE,51.193611,14.519722,568\n',
      }),
    );

    final result = await lookup.lookup(const ['DLH700']);

    expect((result as RouteFound).route.origin.iataCode, isNull);
  });

  test('reports not found when no candidate has a row', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv': _dlhRoutes,
      }),
    );

    expect(await lookup.lookup(const ['DLH123']), isA<RouteNotFound>());
  });

  test('reports not found when both route file shapes are missing', () async {
    final lookup = RouteLookup(client: _clientServing(const {}));

    expect(await lookup.lookup(const ['DLH400']), isA<RouteNotFound>());
  });

  test('reports not found for an empty candidate list', () async {
    final lookup = RouteLookup(client: _clientServing(const {}));

    expect(await lookup.lookup(const []), isA<RouteNotFound>());
  });

  test('reports a failure when the request throws', () async {
    final lookup = RouteLookup(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(await lookup.lookup(const ['DLH400']), isA<RouteLookupFailure>());
  });

  test('reports a failure on a server error', () async {
    final lookup = RouteLookup(
      client: MockClient((_) async => http.Response('', 500)),
    );

    expect(await lookup.lookup(const ['DLH400']), isA<RouteLookupFailure>());
  });

  test('reports a failure on a malformed route row', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv': '${_routeHeader}DLH400,DLH\n',
      }),
    );

    expect(await lookup.lookup(const ['DLH400']), isA<RouteLookupFailure>());
  });

  test('reports a failure on malformed airport coordinates', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv': _dlhRoutes,
        '$_base/airports/schema-01/E/ED.csv':
            '${_airportHeader}EDDF,Frankfurt Airport,EDDF,FRA,Frankfurt,DE,north,east,364\n',
        '$_base/airports/schema-01/K/KJ.csv': _kjAirports,
      }),
    );

    expect(await lookup.lookup(const ['DLH400']), isA<RouteLookupFailure>());
  });

  test('reports not found when an airport is missing from its file', () async {
    final lookup = RouteLookup(
      client: _clientServing({
        '$_base/routes/schema-01/D/DLH-all.csv': _dlhRoutes,
        '$_base/airports/schema-01/E/ED.csv': _edAirports,
        '$_base/airports/schema-01/K/KJ.csv': _airportHeader,
      }),
    );

    expect(await lookup.lookup(const ['DLH400']), isA<RouteNotFound>());
  });
}
