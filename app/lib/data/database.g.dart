// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FlightsTable extends Flights with TableInfo<$FlightsTable, FlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FlightLookupKind, String>
  lookupKind = GeneratedColumn<String>(
    'lookup_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FlightLookupKind>($FlightsTable.$converterlookupKind);
  static const VerificationMeta _lookupValueMeta = const VerificationMeta(
    'lookupValue',
  );
  @override
  late final GeneratedColumn<String> lookupValue = GeneratedColumn<String>(
    'lookup_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departureDateMeta = const VerificationMeta(
    'departureDate',
  );
  @override
  late final GeneratedColumn<String> departureDate = GeneratedColumn<String>(
    'departure_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hexAddressMeta = const VerificationMeta(
    'hexAddress',
  );
  @override
  late final GeneratedColumn<String> hexAddress = GeneratedColumn<String>(
    'hex_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCallsignMeta = const VerificationMeta(
    'expectedCallsign',
  );
  @override
  late final GeneratedColumn<String> expectedCallsign = GeneratedColumn<String>(
    'expected_callsign',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originIcaoCodeMeta = const VerificationMeta(
    'originIcaoCode',
  );
  @override
  late final GeneratedColumn<String> originIcaoCode = GeneratedColumn<String>(
    'origin_icao_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originIataCodeMeta = const VerificationMeta(
    'originIataCode',
  );
  @override
  late final GeneratedColumn<String> originIataCode = GeneratedColumn<String>(
    'origin_iata_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originNameMeta = const VerificationMeta(
    'originName',
  );
  @override
  late final GeneratedColumn<String> originName = GeneratedColumn<String>(
    'origin_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originLocationMeta = const VerificationMeta(
    'originLocation',
  );
  @override
  late final GeneratedColumn<String> originLocation = GeneratedColumn<String>(
    'origin_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originLatitudeMeta = const VerificationMeta(
    'originLatitude',
  );
  @override
  late final GeneratedColumn<double> originLatitude = GeneratedColumn<double>(
    'origin_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originLongitudeMeta = const VerificationMeta(
    'originLongitude',
  );
  @override
  late final GeneratedColumn<double> originLongitude = GeneratedColumn<double>(
    'origin_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationIcaoCodeMeta =
      const VerificationMeta('destinationIcaoCode');
  @override
  late final GeneratedColumn<String> destinationIcaoCode =
      GeneratedColumn<String>(
        'destination_icao_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationIataCodeMeta =
      const VerificationMeta('destinationIataCode');
  @override
  late final GeneratedColumn<String> destinationIataCode =
      GeneratedColumn<String>(
        'destination_iata_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationNameMeta = const VerificationMeta(
    'destinationName',
  );
  @override
  late final GeneratedColumn<String> destinationName = GeneratedColumn<String>(
    'destination_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationLocationMeta =
      const VerificationMeta('destinationLocation');
  @override
  late final GeneratedColumn<String> destinationLocation =
      GeneratedColumn<String>(
        'destination_location',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationLatitudeMeta =
      const VerificationMeta('destinationLatitude');
  @override
  late final GeneratedColumn<double> destinationLatitude =
      GeneratedColumn<double>(
        'destination_latitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationLongitudeMeta =
      const VerificationMeta('destinationLongitude');
  @override
  late final GeneratedColumn<double> destinationLongitude =
      GeneratedColumn<double>(
        'destination_longitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hasBeenAirborneMeta = const VerificationMeta(
    'hasBeenAirborne',
  );
  @override
  late final GeneratedColumn<bool> hasBeenAirborne = GeneratedColumn<bool>(
    'has_been_airborne',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_been_airborne" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastKnownOnGroundMeta = const VerificationMeta(
    'lastKnownOnGround',
  );
  @override
  late final GeneratedColumn<bool> lastKnownOnGround = GeneratedColumn<bool>(
    'last_known_on_ground',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_known_on_ground" IN (0, 1))',
    ),
  );
  static const VerificationMeta _latestLatitudeMeta = const VerificationMeta(
    'latestLatitude',
  );
  @override
  late final GeneratedColumn<double> latestLatitude = GeneratedColumn<double>(
    'latest_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestLongitudeMeta = const VerificationMeta(
    'latestLongitude',
  );
  @override
  late final GeneratedColumn<double> latestLongitude = GeneratedColumn<double>(
    'latest_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestTimestampMeta = const VerificationMeta(
    'latestTimestamp',
  );
  @override
  late final GeneratedColumn<int> latestTimestamp = GeneratedColumn<int>(
    'latest_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestBarometricAltitudeFeetMeta =
      const VerificationMeta('latestBarometricAltitudeFeet');
  @override
  late final GeneratedColumn<double> latestBarometricAltitudeFeet =
      GeneratedColumn<double>(
        'latest_barometric_altitude_feet',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestOnGroundMeta = const VerificationMeta(
    'latestOnGround',
  );
  @override
  late final GeneratedColumn<bool> latestOnGround = GeneratedColumn<bool>(
    'latest_on_ground',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("latest_on_ground" IN (0, 1))',
    ),
  );
  static const VerificationMeta _latestGeometricAltitudeFeetMeta =
      const VerificationMeta('latestGeometricAltitudeFeet');
  @override
  late final GeneratedColumn<double> latestGeometricAltitudeFeet =
      GeneratedColumn<double>(
        'latest_geometric_altitude_feet',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestTrackDegreesMeta =
      const VerificationMeta('latestTrackDegrees');
  @override
  late final GeneratedColumn<double> latestTrackDegrees =
      GeneratedColumn<double>(
        'latest_track_degrees',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestTrueHeadingDegreesMeta =
      const VerificationMeta('latestTrueHeadingDegrees');
  @override
  late final GeneratedColumn<double> latestTrueHeadingDegrees =
      GeneratedColumn<double>(
        'latest_true_heading_degrees',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestGroundSpeedKnotsMeta =
      const VerificationMeta('latestGroundSpeedKnots');
  @override
  late final GeneratedColumn<double> latestGroundSpeedKnots =
      GeneratedColumn<double>(
        'latest_ground_speed_knots',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestIndicatedAirspeedKnotsMeta =
      const VerificationMeta('latestIndicatedAirspeedKnots');
  @override
  late final GeneratedColumn<double> latestIndicatedAirspeedKnots =
      GeneratedColumn<double>(
        'latest_indicated_airspeed_knots',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestMachMeta = const VerificationMeta(
    'latestMach',
  );
  @override
  late final GeneratedColumn<double> latestMach = GeneratedColumn<double>(
    'latest_mach',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestVerticalRateFeetPerMinuteMeta =
      const VerificationMeta('latestVerticalRateFeetPerMinute');
  @override
  late final GeneratedColumn<double> latestVerticalRateFeetPerMinute =
      GeneratedColumn<double>(
        'latest_vertical_rate_feet_per_minute',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lookupKind,
    lookupValue,
    departureDate,
    note,
    hexAddress,
    expectedCallsign,
    originIcaoCode,
    originIataCode,
    originName,
    originLocation,
    originLatitude,
    originLongitude,
    destinationIcaoCode,
    destinationIataCode,
    destinationName,
    destinationLocation,
    destinationLatitude,
    destinationLongitude,
    hasBeenAirborne,
    lastKnownOnGround,
    latestLatitude,
    latestLongitude,
    latestTimestamp,
    latestBarometricAltitudeFeet,
    latestOnGround,
    latestGeometricAltitudeFeet,
    latestTrackDegrees,
    latestTrueHeadingDegrees,
    latestGroundSpeedKnots,
    latestIndicatedAirspeedKnots,
    latestMach,
    latestVerticalRateFeetPerMinute,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flights';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lookup_value')) {
      context.handle(
        _lookupValueMeta,
        lookupValue.isAcceptableOrUnknown(
          data['lookup_value']!,
          _lookupValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lookupValueMeta);
    }
    if (data.containsKey('departure_date')) {
      context.handle(
        _departureDateMeta,
        departureDate.isAcceptableOrUnknown(
          data['departure_date']!,
          _departureDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_departureDateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('hex_address')) {
      context.handle(
        _hexAddressMeta,
        hexAddress.isAcceptableOrUnknown(data['hex_address']!, _hexAddressMeta),
      );
    }
    if (data.containsKey('expected_callsign')) {
      context.handle(
        _expectedCallsignMeta,
        expectedCallsign.isAcceptableOrUnknown(
          data['expected_callsign']!,
          _expectedCallsignMeta,
        ),
      );
    }
    if (data.containsKey('origin_icao_code')) {
      context.handle(
        _originIcaoCodeMeta,
        originIcaoCode.isAcceptableOrUnknown(
          data['origin_icao_code']!,
          _originIcaoCodeMeta,
        ),
      );
    }
    if (data.containsKey('origin_iata_code')) {
      context.handle(
        _originIataCodeMeta,
        originIataCode.isAcceptableOrUnknown(
          data['origin_iata_code']!,
          _originIataCodeMeta,
        ),
      );
    }
    if (data.containsKey('origin_name')) {
      context.handle(
        _originNameMeta,
        originName.isAcceptableOrUnknown(data['origin_name']!, _originNameMeta),
      );
    }
    if (data.containsKey('origin_location')) {
      context.handle(
        _originLocationMeta,
        originLocation.isAcceptableOrUnknown(
          data['origin_location']!,
          _originLocationMeta,
        ),
      );
    }
    if (data.containsKey('origin_latitude')) {
      context.handle(
        _originLatitudeMeta,
        originLatitude.isAcceptableOrUnknown(
          data['origin_latitude']!,
          _originLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('origin_longitude')) {
      context.handle(
        _originLongitudeMeta,
        originLongitude.isAcceptableOrUnknown(
          data['origin_longitude']!,
          _originLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('destination_icao_code')) {
      context.handle(
        _destinationIcaoCodeMeta,
        destinationIcaoCode.isAcceptableOrUnknown(
          data['destination_icao_code']!,
          _destinationIcaoCodeMeta,
        ),
      );
    }
    if (data.containsKey('destination_iata_code')) {
      context.handle(
        _destinationIataCodeMeta,
        destinationIataCode.isAcceptableOrUnknown(
          data['destination_iata_code']!,
          _destinationIataCodeMeta,
        ),
      );
    }
    if (data.containsKey('destination_name')) {
      context.handle(
        _destinationNameMeta,
        destinationName.isAcceptableOrUnknown(
          data['destination_name']!,
          _destinationNameMeta,
        ),
      );
    }
    if (data.containsKey('destination_location')) {
      context.handle(
        _destinationLocationMeta,
        destinationLocation.isAcceptableOrUnknown(
          data['destination_location']!,
          _destinationLocationMeta,
        ),
      );
    }
    if (data.containsKey('destination_latitude')) {
      context.handle(
        _destinationLatitudeMeta,
        destinationLatitude.isAcceptableOrUnknown(
          data['destination_latitude']!,
          _destinationLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('destination_longitude')) {
      context.handle(
        _destinationLongitudeMeta,
        destinationLongitude.isAcceptableOrUnknown(
          data['destination_longitude']!,
          _destinationLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('has_been_airborne')) {
      context.handle(
        _hasBeenAirborneMeta,
        hasBeenAirborne.isAcceptableOrUnknown(
          data['has_been_airborne']!,
          _hasBeenAirborneMeta,
        ),
      );
    }
    if (data.containsKey('last_known_on_ground')) {
      context.handle(
        _lastKnownOnGroundMeta,
        lastKnownOnGround.isAcceptableOrUnknown(
          data['last_known_on_ground']!,
          _lastKnownOnGroundMeta,
        ),
      );
    }
    if (data.containsKey('latest_latitude')) {
      context.handle(
        _latestLatitudeMeta,
        latestLatitude.isAcceptableOrUnknown(
          data['latest_latitude']!,
          _latestLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('latest_longitude')) {
      context.handle(
        _latestLongitudeMeta,
        latestLongitude.isAcceptableOrUnknown(
          data['latest_longitude']!,
          _latestLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('latest_timestamp')) {
      context.handle(
        _latestTimestampMeta,
        latestTimestamp.isAcceptableOrUnknown(
          data['latest_timestamp']!,
          _latestTimestampMeta,
        ),
      );
    }
    if (data.containsKey('latest_barometric_altitude_feet')) {
      context.handle(
        _latestBarometricAltitudeFeetMeta,
        latestBarometricAltitudeFeet.isAcceptableOrUnknown(
          data['latest_barometric_altitude_feet']!,
          _latestBarometricAltitudeFeetMeta,
        ),
      );
    }
    if (data.containsKey('latest_on_ground')) {
      context.handle(
        _latestOnGroundMeta,
        latestOnGround.isAcceptableOrUnknown(
          data['latest_on_ground']!,
          _latestOnGroundMeta,
        ),
      );
    }
    if (data.containsKey('latest_geometric_altitude_feet')) {
      context.handle(
        _latestGeometricAltitudeFeetMeta,
        latestGeometricAltitudeFeet.isAcceptableOrUnknown(
          data['latest_geometric_altitude_feet']!,
          _latestGeometricAltitudeFeetMeta,
        ),
      );
    }
    if (data.containsKey('latest_track_degrees')) {
      context.handle(
        _latestTrackDegreesMeta,
        latestTrackDegrees.isAcceptableOrUnknown(
          data['latest_track_degrees']!,
          _latestTrackDegreesMeta,
        ),
      );
    }
    if (data.containsKey('latest_true_heading_degrees')) {
      context.handle(
        _latestTrueHeadingDegreesMeta,
        latestTrueHeadingDegrees.isAcceptableOrUnknown(
          data['latest_true_heading_degrees']!,
          _latestTrueHeadingDegreesMeta,
        ),
      );
    }
    if (data.containsKey('latest_ground_speed_knots')) {
      context.handle(
        _latestGroundSpeedKnotsMeta,
        latestGroundSpeedKnots.isAcceptableOrUnknown(
          data['latest_ground_speed_knots']!,
          _latestGroundSpeedKnotsMeta,
        ),
      );
    }
    if (data.containsKey('latest_indicated_airspeed_knots')) {
      context.handle(
        _latestIndicatedAirspeedKnotsMeta,
        latestIndicatedAirspeedKnots.isAcceptableOrUnknown(
          data['latest_indicated_airspeed_knots']!,
          _latestIndicatedAirspeedKnotsMeta,
        ),
      );
    }
    if (data.containsKey('latest_mach')) {
      context.handle(
        _latestMachMeta,
        latestMach.isAcceptableOrUnknown(data['latest_mach']!, _latestMachMeta),
      );
    }
    if (data.containsKey('latest_vertical_rate_feet_per_minute')) {
      context.handle(
        _latestVerticalRateFeetPerMinuteMeta,
        latestVerticalRateFeetPerMinute.isAcceptableOrUnknown(
          data['latest_vertical_rate_feet_per_minute']!,
          _latestVerticalRateFeetPerMinuteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lookupKind: $FlightsTable.$converterlookupKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lookup_kind'],
        )!,
      ),
      lookupValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lookup_value'],
      )!,
      departureDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}departure_date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      hexAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hex_address'],
      ),
      expectedCallsign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_callsign'],
      ),
      originIcaoCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_icao_code'],
      ),
      originIataCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_iata_code'],
      ),
      originName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_name'],
      ),
      originLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_location'],
      ),
      originLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}origin_latitude'],
      ),
      originLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}origin_longitude'],
      ),
      destinationIcaoCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_icao_code'],
      ),
      destinationIataCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_iata_code'],
      ),
      destinationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_name'],
      ),
      destinationLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_location'],
      ),
      destinationLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}destination_latitude'],
      ),
      destinationLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}destination_longitude'],
      ),
      hasBeenAirborne: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_been_airborne'],
      )!,
      lastKnownOnGround: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_known_on_ground'],
      ),
      latestLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_latitude'],
      ),
      latestLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_longitude'],
      ),
      latestTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_timestamp'],
      ),
      latestBarometricAltitudeFeet: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_barometric_altitude_feet'],
      ),
      latestOnGround: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}latest_on_ground'],
      ),
      latestGeometricAltitudeFeet: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_geometric_altitude_feet'],
      ),
      latestTrackDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_track_degrees'],
      ),
      latestTrueHeadingDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_true_heading_degrees'],
      ),
      latestGroundSpeedKnots: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_ground_speed_knots'],
      ),
      latestIndicatedAirspeedKnots: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_indicated_airspeed_knots'],
      ),
      latestMach: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_mach'],
      ),
      latestVerticalRateFeetPerMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_vertical_rate_feet_per_minute'],
      ),
    );
  }

  @override
  $FlightsTable createAlias(String alias) {
    return $FlightsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FlightLookupKind, String, String>
  $converterlookupKind = const EnumNameConverter<FlightLookupKind>(
    FlightLookupKind.values,
  );
}

class FlightRow extends DataClass implements Insertable<FlightRow> {
  final int id;
  final FlightLookupKind lookupKind;
  final String lookupValue;
  final String departureDate;
  final String? note;
  final String? hexAddress;
  final String? expectedCallsign;
  final String? originIcaoCode;
  final String? originIataCode;
  final String? originName;
  final String? originLocation;
  final double? originLatitude;
  final double? originLongitude;
  final String? destinationIcaoCode;
  final String? destinationIataCode;
  final String? destinationName;
  final String? destinationLocation;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final bool hasBeenAirborne;
  final bool? lastKnownOnGround;
  final double? latestLatitude;
  final double? latestLongitude;
  final int? latestTimestamp;
  final double? latestBarometricAltitudeFeet;
  final bool? latestOnGround;
  final double? latestGeometricAltitudeFeet;
  final double? latestTrackDegrees;
  final double? latestTrueHeadingDegrees;
  final double? latestGroundSpeedKnots;
  final double? latestIndicatedAirspeedKnots;
  final double? latestMach;
  final double? latestVerticalRateFeetPerMinute;
  const FlightRow({
    required this.id,
    required this.lookupKind,
    required this.lookupValue,
    required this.departureDate,
    this.note,
    this.hexAddress,
    this.expectedCallsign,
    this.originIcaoCode,
    this.originIataCode,
    this.originName,
    this.originLocation,
    this.originLatitude,
    this.originLongitude,
    this.destinationIcaoCode,
    this.destinationIataCode,
    this.destinationName,
    this.destinationLocation,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.hasBeenAirborne,
    this.lastKnownOnGround,
    this.latestLatitude,
    this.latestLongitude,
    this.latestTimestamp,
    this.latestBarometricAltitudeFeet,
    this.latestOnGround,
    this.latestGeometricAltitudeFeet,
    this.latestTrackDegrees,
    this.latestTrueHeadingDegrees,
    this.latestGroundSpeedKnots,
    this.latestIndicatedAirspeedKnots,
    this.latestMach,
    this.latestVerticalRateFeetPerMinute,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['lookup_kind'] = Variable<String>(
        $FlightsTable.$converterlookupKind.toSql(lookupKind),
      );
    }
    map['lookup_value'] = Variable<String>(lookupValue);
    map['departure_date'] = Variable<String>(departureDate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || hexAddress != null) {
      map['hex_address'] = Variable<String>(hexAddress);
    }
    if (!nullToAbsent || expectedCallsign != null) {
      map['expected_callsign'] = Variable<String>(expectedCallsign);
    }
    if (!nullToAbsent || originIcaoCode != null) {
      map['origin_icao_code'] = Variable<String>(originIcaoCode);
    }
    if (!nullToAbsent || originIataCode != null) {
      map['origin_iata_code'] = Variable<String>(originIataCode);
    }
    if (!nullToAbsent || originName != null) {
      map['origin_name'] = Variable<String>(originName);
    }
    if (!nullToAbsent || originLocation != null) {
      map['origin_location'] = Variable<String>(originLocation);
    }
    if (!nullToAbsent || originLatitude != null) {
      map['origin_latitude'] = Variable<double>(originLatitude);
    }
    if (!nullToAbsent || originLongitude != null) {
      map['origin_longitude'] = Variable<double>(originLongitude);
    }
    if (!nullToAbsent || destinationIcaoCode != null) {
      map['destination_icao_code'] = Variable<String>(destinationIcaoCode);
    }
    if (!nullToAbsent || destinationIataCode != null) {
      map['destination_iata_code'] = Variable<String>(destinationIataCode);
    }
    if (!nullToAbsent || destinationName != null) {
      map['destination_name'] = Variable<String>(destinationName);
    }
    if (!nullToAbsent || destinationLocation != null) {
      map['destination_location'] = Variable<String>(destinationLocation);
    }
    if (!nullToAbsent || destinationLatitude != null) {
      map['destination_latitude'] = Variable<double>(destinationLatitude);
    }
    if (!nullToAbsent || destinationLongitude != null) {
      map['destination_longitude'] = Variable<double>(destinationLongitude);
    }
    map['has_been_airborne'] = Variable<bool>(hasBeenAirborne);
    if (!nullToAbsent || lastKnownOnGround != null) {
      map['last_known_on_ground'] = Variable<bool>(lastKnownOnGround);
    }
    if (!nullToAbsent || latestLatitude != null) {
      map['latest_latitude'] = Variable<double>(latestLatitude);
    }
    if (!nullToAbsent || latestLongitude != null) {
      map['latest_longitude'] = Variable<double>(latestLongitude);
    }
    if (!nullToAbsent || latestTimestamp != null) {
      map['latest_timestamp'] = Variable<int>(latestTimestamp);
    }
    if (!nullToAbsent || latestBarometricAltitudeFeet != null) {
      map['latest_barometric_altitude_feet'] = Variable<double>(
        latestBarometricAltitudeFeet,
      );
    }
    if (!nullToAbsent || latestOnGround != null) {
      map['latest_on_ground'] = Variable<bool>(latestOnGround);
    }
    if (!nullToAbsent || latestGeometricAltitudeFeet != null) {
      map['latest_geometric_altitude_feet'] = Variable<double>(
        latestGeometricAltitudeFeet,
      );
    }
    if (!nullToAbsent || latestTrackDegrees != null) {
      map['latest_track_degrees'] = Variable<double>(latestTrackDegrees);
    }
    if (!nullToAbsent || latestTrueHeadingDegrees != null) {
      map['latest_true_heading_degrees'] = Variable<double>(
        latestTrueHeadingDegrees,
      );
    }
    if (!nullToAbsent || latestGroundSpeedKnots != null) {
      map['latest_ground_speed_knots'] = Variable<double>(
        latestGroundSpeedKnots,
      );
    }
    if (!nullToAbsent || latestIndicatedAirspeedKnots != null) {
      map['latest_indicated_airspeed_knots'] = Variable<double>(
        latestIndicatedAirspeedKnots,
      );
    }
    if (!nullToAbsent || latestMach != null) {
      map['latest_mach'] = Variable<double>(latestMach);
    }
    if (!nullToAbsent || latestVerticalRateFeetPerMinute != null) {
      map['latest_vertical_rate_feet_per_minute'] = Variable<double>(
        latestVerticalRateFeetPerMinute,
      );
    }
    return map;
  }

  FlightsCompanion toCompanion(bool nullToAbsent) {
    return FlightsCompanion(
      id: Value(id),
      lookupKind: Value(lookupKind),
      lookupValue: Value(lookupValue),
      departureDate: Value(departureDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      hexAddress: hexAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(hexAddress),
      expectedCallsign: expectedCallsign == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCallsign),
      originIcaoCode: originIcaoCode == null && nullToAbsent
          ? const Value.absent()
          : Value(originIcaoCode),
      originIataCode: originIataCode == null && nullToAbsent
          ? const Value.absent()
          : Value(originIataCode),
      originName: originName == null && nullToAbsent
          ? const Value.absent()
          : Value(originName),
      originLocation: originLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(originLocation),
      originLatitude: originLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(originLatitude),
      originLongitude: originLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(originLongitude),
      destinationIcaoCode: destinationIcaoCode == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationIcaoCode),
      destinationIataCode: destinationIataCode == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationIataCode),
      destinationName: destinationName == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationName),
      destinationLocation: destinationLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationLocation),
      destinationLatitude: destinationLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationLatitude),
      destinationLongitude: destinationLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationLongitude),
      hasBeenAirborne: Value(hasBeenAirborne),
      lastKnownOnGround: lastKnownOnGround == null && nullToAbsent
          ? const Value.absent()
          : Value(lastKnownOnGround),
      latestLatitude: latestLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latestLatitude),
      latestLongitude: latestLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latestLongitude),
      latestTimestamp: latestTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(latestTimestamp),
      latestBarometricAltitudeFeet:
          latestBarometricAltitudeFeet == null && nullToAbsent
          ? const Value.absent()
          : Value(latestBarometricAltitudeFeet),
      latestOnGround: latestOnGround == null && nullToAbsent
          ? const Value.absent()
          : Value(latestOnGround),
      latestGeometricAltitudeFeet:
          latestGeometricAltitudeFeet == null && nullToAbsent
          ? const Value.absent()
          : Value(latestGeometricAltitudeFeet),
      latestTrackDegrees: latestTrackDegrees == null && nullToAbsent
          ? const Value.absent()
          : Value(latestTrackDegrees),
      latestTrueHeadingDegrees: latestTrueHeadingDegrees == null && nullToAbsent
          ? const Value.absent()
          : Value(latestTrueHeadingDegrees),
      latestGroundSpeedKnots: latestGroundSpeedKnots == null && nullToAbsent
          ? const Value.absent()
          : Value(latestGroundSpeedKnots),
      latestIndicatedAirspeedKnots:
          latestIndicatedAirspeedKnots == null && nullToAbsent
          ? const Value.absent()
          : Value(latestIndicatedAirspeedKnots),
      latestMach: latestMach == null && nullToAbsent
          ? const Value.absent()
          : Value(latestMach),
      latestVerticalRateFeetPerMinute:
          latestVerticalRateFeetPerMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(latestVerticalRateFeetPerMinute),
    );
  }

  factory FlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlightRow(
      id: serializer.fromJson<int>(json['id']),
      lookupKind: $FlightsTable.$converterlookupKind.fromJson(
        serializer.fromJson<String>(json['lookupKind']),
      ),
      lookupValue: serializer.fromJson<String>(json['lookupValue']),
      departureDate: serializer.fromJson<String>(json['departureDate']),
      note: serializer.fromJson<String?>(json['note']),
      hexAddress: serializer.fromJson<String?>(json['hexAddress']),
      expectedCallsign: serializer.fromJson<String?>(json['expectedCallsign']),
      originIcaoCode: serializer.fromJson<String?>(json['originIcaoCode']),
      originIataCode: serializer.fromJson<String?>(json['originIataCode']),
      originName: serializer.fromJson<String?>(json['originName']),
      originLocation: serializer.fromJson<String?>(json['originLocation']),
      originLatitude: serializer.fromJson<double?>(json['originLatitude']),
      originLongitude: serializer.fromJson<double?>(json['originLongitude']),
      destinationIcaoCode: serializer.fromJson<String?>(
        json['destinationIcaoCode'],
      ),
      destinationIataCode: serializer.fromJson<String?>(
        json['destinationIataCode'],
      ),
      destinationName: serializer.fromJson<String?>(json['destinationName']),
      destinationLocation: serializer.fromJson<String?>(
        json['destinationLocation'],
      ),
      destinationLatitude: serializer.fromJson<double?>(
        json['destinationLatitude'],
      ),
      destinationLongitude: serializer.fromJson<double?>(
        json['destinationLongitude'],
      ),
      hasBeenAirborne: serializer.fromJson<bool>(json['hasBeenAirborne']),
      lastKnownOnGround: serializer.fromJson<bool?>(json['lastKnownOnGround']),
      latestLatitude: serializer.fromJson<double?>(json['latestLatitude']),
      latestLongitude: serializer.fromJson<double?>(json['latestLongitude']),
      latestTimestamp: serializer.fromJson<int?>(json['latestTimestamp']),
      latestBarometricAltitudeFeet: serializer.fromJson<double?>(
        json['latestBarometricAltitudeFeet'],
      ),
      latestOnGround: serializer.fromJson<bool?>(json['latestOnGround']),
      latestGeometricAltitudeFeet: serializer.fromJson<double?>(
        json['latestGeometricAltitudeFeet'],
      ),
      latestTrackDegrees: serializer.fromJson<double?>(
        json['latestTrackDegrees'],
      ),
      latestTrueHeadingDegrees: serializer.fromJson<double?>(
        json['latestTrueHeadingDegrees'],
      ),
      latestGroundSpeedKnots: serializer.fromJson<double?>(
        json['latestGroundSpeedKnots'],
      ),
      latestIndicatedAirspeedKnots: serializer.fromJson<double?>(
        json['latestIndicatedAirspeedKnots'],
      ),
      latestMach: serializer.fromJson<double?>(json['latestMach']),
      latestVerticalRateFeetPerMinute: serializer.fromJson<double?>(
        json['latestVerticalRateFeetPerMinute'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lookupKind': serializer.toJson<String>(
        $FlightsTable.$converterlookupKind.toJson(lookupKind),
      ),
      'lookupValue': serializer.toJson<String>(lookupValue),
      'departureDate': serializer.toJson<String>(departureDate),
      'note': serializer.toJson<String?>(note),
      'hexAddress': serializer.toJson<String?>(hexAddress),
      'expectedCallsign': serializer.toJson<String?>(expectedCallsign),
      'originIcaoCode': serializer.toJson<String?>(originIcaoCode),
      'originIataCode': serializer.toJson<String?>(originIataCode),
      'originName': serializer.toJson<String?>(originName),
      'originLocation': serializer.toJson<String?>(originLocation),
      'originLatitude': serializer.toJson<double?>(originLatitude),
      'originLongitude': serializer.toJson<double?>(originLongitude),
      'destinationIcaoCode': serializer.toJson<String?>(destinationIcaoCode),
      'destinationIataCode': serializer.toJson<String?>(destinationIataCode),
      'destinationName': serializer.toJson<String?>(destinationName),
      'destinationLocation': serializer.toJson<String?>(destinationLocation),
      'destinationLatitude': serializer.toJson<double?>(destinationLatitude),
      'destinationLongitude': serializer.toJson<double?>(destinationLongitude),
      'hasBeenAirborne': serializer.toJson<bool>(hasBeenAirborne),
      'lastKnownOnGround': serializer.toJson<bool?>(lastKnownOnGround),
      'latestLatitude': serializer.toJson<double?>(latestLatitude),
      'latestLongitude': serializer.toJson<double?>(latestLongitude),
      'latestTimestamp': serializer.toJson<int?>(latestTimestamp),
      'latestBarometricAltitudeFeet': serializer.toJson<double?>(
        latestBarometricAltitudeFeet,
      ),
      'latestOnGround': serializer.toJson<bool?>(latestOnGround),
      'latestGeometricAltitudeFeet': serializer.toJson<double?>(
        latestGeometricAltitudeFeet,
      ),
      'latestTrackDegrees': serializer.toJson<double?>(latestTrackDegrees),
      'latestTrueHeadingDegrees': serializer.toJson<double?>(
        latestTrueHeadingDegrees,
      ),
      'latestGroundSpeedKnots': serializer.toJson<double?>(
        latestGroundSpeedKnots,
      ),
      'latestIndicatedAirspeedKnots': serializer.toJson<double?>(
        latestIndicatedAirspeedKnots,
      ),
      'latestMach': serializer.toJson<double?>(latestMach),
      'latestVerticalRateFeetPerMinute': serializer.toJson<double?>(
        latestVerticalRateFeetPerMinute,
      ),
    };
  }

  FlightRow copyWith({
    int? id,
    FlightLookupKind? lookupKind,
    String? lookupValue,
    String? departureDate,
    Value<String?> note = const Value.absent(),
    Value<String?> hexAddress = const Value.absent(),
    Value<String?> expectedCallsign = const Value.absent(),
    Value<String?> originIcaoCode = const Value.absent(),
    Value<String?> originIataCode = const Value.absent(),
    Value<String?> originName = const Value.absent(),
    Value<String?> originLocation = const Value.absent(),
    Value<double?> originLatitude = const Value.absent(),
    Value<double?> originLongitude = const Value.absent(),
    Value<String?> destinationIcaoCode = const Value.absent(),
    Value<String?> destinationIataCode = const Value.absent(),
    Value<String?> destinationName = const Value.absent(),
    Value<String?> destinationLocation = const Value.absent(),
    Value<double?> destinationLatitude = const Value.absent(),
    Value<double?> destinationLongitude = const Value.absent(),
    bool? hasBeenAirborne,
    Value<bool?> lastKnownOnGround = const Value.absent(),
    Value<double?> latestLatitude = const Value.absent(),
    Value<double?> latestLongitude = const Value.absent(),
    Value<int?> latestTimestamp = const Value.absent(),
    Value<double?> latestBarometricAltitudeFeet = const Value.absent(),
    Value<bool?> latestOnGround = const Value.absent(),
    Value<double?> latestGeometricAltitudeFeet = const Value.absent(),
    Value<double?> latestTrackDegrees = const Value.absent(),
    Value<double?> latestTrueHeadingDegrees = const Value.absent(),
    Value<double?> latestGroundSpeedKnots = const Value.absent(),
    Value<double?> latestIndicatedAirspeedKnots = const Value.absent(),
    Value<double?> latestMach = const Value.absent(),
    Value<double?> latestVerticalRateFeetPerMinute = const Value.absent(),
  }) => FlightRow(
    id: id ?? this.id,
    lookupKind: lookupKind ?? this.lookupKind,
    lookupValue: lookupValue ?? this.lookupValue,
    departureDate: departureDate ?? this.departureDate,
    note: note.present ? note.value : this.note,
    hexAddress: hexAddress.present ? hexAddress.value : this.hexAddress,
    expectedCallsign: expectedCallsign.present
        ? expectedCallsign.value
        : this.expectedCallsign,
    originIcaoCode: originIcaoCode.present
        ? originIcaoCode.value
        : this.originIcaoCode,
    originIataCode: originIataCode.present
        ? originIataCode.value
        : this.originIataCode,
    originName: originName.present ? originName.value : this.originName,
    originLocation: originLocation.present
        ? originLocation.value
        : this.originLocation,
    originLatitude: originLatitude.present
        ? originLatitude.value
        : this.originLatitude,
    originLongitude: originLongitude.present
        ? originLongitude.value
        : this.originLongitude,
    destinationIcaoCode: destinationIcaoCode.present
        ? destinationIcaoCode.value
        : this.destinationIcaoCode,
    destinationIataCode: destinationIataCode.present
        ? destinationIataCode.value
        : this.destinationIataCode,
    destinationName: destinationName.present
        ? destinationName.value
        : this.destinationName,
    destinationLocation: destinationLocation.present
        ? destinationLocation.value
        : this.destinationLocation,
    destinationLatitude: destinationLatitude.present
        ? destinationLatitude.value
        : this.destinationLatitude,
    destinationLongitude: destinationLongitude.present
        ? destinationLongitude.value
        : this.destinationLongitude,
    hasBeenAirborne: hasBeenAirborne ?? this.hasBeenAirborne,
    lastKnownOnGround: lastKnownOnGround.present
        ? lastKnownOnGround.value
        : this.lastKnownOnGround,
    latestLatitude: latestLatitude.present
        ? latestLatitude.value
        : this.latestLatitude,
    latestLongitude: latestLongitude.present
        ? latestLongitude.value
        : this.latestLongitude,
    latestTimestamp: latestTimestamp.present
        ? latestTimestamp.value
        : this.latestTimestamp,
    latestBarometricAltitudeFeet: latestBarometricAltitudeFeet.present
        ? latestBarometricAltitudeFeet.value
        : this.latestBarometricAltitudeFeet,
    latestOnGround: latestOnGround.present
        ? latestOnGround.value
        : this.latestOnGround,
    latestGeometricAltitudeFeet: latestGeometricAltitudeFeet.present
        ? latestGeometricAltitudeFeet.value
        : this.latestGeometricAltitudeFeet,
    latestTrackDegrees: latestTrackDegrees.present
        ? latestTrackDegrees.value
        : this.latestTrackDegrees,
    latestTrueHeadingDegrees: latestTrueHeadingDegrees.present
        ? latestTrueHeadingDegrees.value
        : this.latestTrueHeadingDegrees,
    latestGroundSpeedKnots: latestGroundSpeedKnots.present
        ? latestGroundSpeedKnots.value
        : this.latestGroundSpeedKnots,
    latestIndicatedAirspeedKnots: latestIndicatedAirspeedKnots.present
        ? latestIndicatedAirspeedKnots.value
        : this.latestIndicatedAirspeedKnots,
    latestMach: latestMach.present ? latestMach.value : this.latestMach,
    latestVerticalRateFeetPerMinute: latestVerticalRateFeetPerMinute.present
        ? latestVerticalRateFeetPerMinute.value
        : this.latestVerticalRateFeetPerMinute,
  );
  FlightRow copyWithCompanion(FlightsCompanion data) {
    return FlightRow(
      id: data.id.present ? data.id.value : this.id,
      lookupKind: data.lookupKind.present
          ? data.lookupKind.value
          : this.lookupKind,
      lookupValue: data.lookupValue.present
          ? data.lookupValue.value
          : this.lookupValue,
      departureDate: data.departureDate.present
          ? data.departureDate.value
          : this.departureDate,
      note: data.note.present ? data.note.value : this.note,
      hexAddress: data.hexAddress.present
          ? data.hexAddress.value
          : this.hexAddress,
      expectedCallsign: data.expectedCallsign.present
          ? data.expectedCallsign.value
          : this.expectedCallsign,
      originIcaoCode: data.originIcaoCode.present
          ? data.originIcaoCode.value
          : this.originIcaoCode,
      originIataCode: data.originIataCode.present
          ? data.originIataCode.value
          : this.originIataCode,
      originName: data.originName.present
          ? data.originName.value
          : this.originName,
      originLocation: data.originLocation.present
          ? data.originLocation.value
          : this.originLocation,
      originLatitude: data.originLatitude.present
          ? data.originLatitude.value
          : this.originLatitude,
      originLongitude: data.originLongitude.present
          ? data.originLongitude.value
          : this.originLongitude,
      destinationIcaoCode: data.destinationIcaoCode.present
          ? data.destinationIcaoCode.value
          : this.destinationIcaoCode,
      destinationIataCode: data.destinationIataCode.present
          ? data.destinationIataCode.value
          : this.destinationIataCode,
      destinationName: data.destinationName.present
          ? data.destinationName.value
          : this.destinationName,
      destinationLocation: data.destinationLocation.present
          ? data.destinationLocation.value
          : this.destinationLocation,
      destinationLatitude: data.destinationLatitude.present
          ? data.destinationLatitude.value
          : this.destinationLatitude,
      destinationLongitude: data.destinationLongitude.present
          ? data.destinationLongitude.value
          : this.destinationLongitude,
      hasBeenAirborne: data.hasBeenAirborne.present
          ? data.hasBeenAirborne.value
          : this.hasBeenAirborne,
      lastKnownOnGround: data.lastKnownOnGround.present
          ? data.lastKnownOnGround.value
          : this.lastKnownOnGround,
      latestLatitude: data.latestLatitude.present
          ? data.latestLatitude.value
          : this.latestLatitude,
      latestLongitude: data.latestLongitude.present
          ? data.latestLongitude.value
          : this.latestLongitude,
      latestTimestamp: data.latestTimestamp.present
          ? data.latestTimestamp.value
          : this.latestTimestamp,
      latestBarometricAltitudeFeet: data.latestBarometricAltitudeFeet.present
          ? data.latestBarometricAltitudeFeet.value
          : this.latestBarometricAltitudeFeet,
      latestOnGround: data.latestOnGround.present
          ? data.latestOnGround.value
          : this.latestOnGround,
      latestGeometricAltitudeFeet: data.latestGeometricAltitudeFeet.present
          ? data.latestGeometricAltitudeFeet.value
          : this.latestGeometricAltitudeFeet,
      latestTrackDegrees: data.latestTrackDegrees.present
          ? data.latestTrackDegrees.value
          : this.latestTrackDegrees,
      latestTrueHeadingDegrees: data.latestTrueHeadingDegrees.present
          ? data.latestTrueHeadingDegrees.value
          : this.latestTrueHeadingDegrees,
      latestGroundSpeedKnots: data.latestGroundSpeedKnots.present
          ? data.latestGroundSpeedKnots.value
          : this.latestGroundSpeedKnots,
      latestIndicatedAirspeedKnots: data.latestIndicatedAirspeedKnots.present
          ? data.latestIndicatedAirspeedKnots.value
          : this.latestIndicatedAirspeedKnots,
      latestMach: data.latestMach.present
          ? data.latestMach.value
          : this.latestMach,
      latestVerticalRateFeetPerMinute:
          data.latestVerticalRateFeetPerMinute.present
          ? data.latestVerticalRateFeetPerMinute.value
          : this.latestVerticalRateFeetPerMinute,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlightRow(')
          ..write('id: $id, ')
          ..write('lookupKind: $lookupKind, ')
          ..write('lookupValue: $lookupValue, ')
          ..write('departureDate: $departureDate, ')
          ..write('note: $note, ')
          ..write('hexAddress: $hexAddress, ')
          ..write('expectedCallsign: $expectedCallsign, ')
          ..write('originIcaoCode: $originIcaoCode, ')
          ..write('originIataCode: $originIataCode, ')
          ..write('originName: $originName, ')
          ..write('originLocation: $originLocation, ')
          ..write('originLatitude: $originLatitude, ')
          ..write('originLongitude: $originLongitude, ')
          ..write('destinationIcaoCode: $destinationIcaoCode, ')
          ..write('destinationIataCode: $destinationIataCode, ')
          ..write('destinationName: $destinationName, ')
          ..write('destinationLocation: $destinationLocation, ')
          ..write('destinationLatitude: $destinationLatitude, ')
          ..write('destinationLongitude: $destinationLongitude, ')
          ..write('hasBeenAirborne: $hasBeenAirborne, ')
          ..write('lastKnownOnGround: $lastKnownOnGround, ')
          ..write('latestLatitude: $latestLatitude, ')
          ..write('latestLongitude: $latestLongitude, ')
          ..write('latestTimestamp: $latestTimestamp, ')
          ..write(
            'latestBarometricAltitudeFeet: $latestBarometricAltitudeFeet, ',
          )
          ..write('latestOnGround: $latestOnGround, ')
          ..write('latestGeometricAltitudeFeet: $latestGeometricAltitudeFeet, ')
          ..write('latestTrackDegrees: $latestTrackDegrees, ')
          ..write('latestTrueHeadingDegrees: $latestTrueHeadingDegrees, ')
          ..write('latestGroundSpeedKnots: $latestGroundSpeedKnots, ')
          ..write(
            'latestIndicatedAirspeedKnots: $latestIndicatedAirspeedKnots, ',
          )
          ..write('latestMach: $latestMach, ')
          ..write(
            'latestVerticalRateFeetPerMinute: $latestVerticalRateFeetPerMinute',
          )
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    lookupKind,
    lookupValue,
    departureDate,
    note,
    hexAddress,
    expectedCallsign,
    originIcaoCode,
    originIataCode,
    originName,
    originLocation,
    originLatitude,
    originLongitude,
    destinationIcaoCode,
    destinationIataCode,
    destinationName,
    destinationLocation,
    destinationLatitude,
    destinationLongitude,
    hasBeenAirborne,
    lastKnownOnGround,
    latestLatitude,
    latestLongitude,
    latestTimestamp,
    latestBarometricAltitudeFeet,
    latestOnGround,
    latestGeometricAltitudeFeet,
    latestTrackDegrees,
    latestTrueHeadingDegrees,
    latestGroundSpeedKnots,
    latestIndicatedAirspeedKnots,
    latestMach,
    latestVerticalRateFeetPerMinute,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightRow &&
          other.id == this.id &&
          other.lookupKind == this.lookupKind &&
          other.lookupValue == this.lookupValue &&
          other.departureDate == this.departureDate &&
          other.note == this.note &&
          other.hexAddress == this.hexAddress &&
          other.expectedCallsign == this.expectedCallsign &&
          other.originIcaoCode == this.originIcaoCode &&
          other.originIataCode == this.originIataCode &&
          other.originName == this.originName &&
          other.originLocation == this.originLocation &&
          other.originLatitude == this.originLatitude &&
          other.originLongitude == this.originLongitude &&
          other.destinationIcaoCode == this.destinationIcaoCode &&
          other.destinationIataCode == this.destinationIataCode &&
          other.destinationName == this.destinationName &&
          other.destinationLocation == this.destinationLocation &&
          other.destinationLatitude == this.destinationLatitude &&
          other.destinationLongitude == this.destinationLongitude &&
          other.hasBeenAirborne == this.hasBeenAirborne &&
          other.lastKnownOnGround == this.lastKnownOnGround &&
          other.latestLatitude == this.latestLatitude &&
          other.latestLongitude == this.latestLongitude &&
          other.latestTimestamp == this.latestTimestamp &&
          other.latestBarometricAltitudeFeet ==
              this.latestBarometricAltitudeFeet &&
          other.latestOnGround == this.latestOnGround &&
          other.latestGeometricAltitudeFeet ==
              this.latestGeometricAltitudeFeet &&
          other.latestTrackDegrees == this.latestTrackDegrees &&
          other.latestTrueHeadingDegrees == this.latestTrueHeadingDegrees &&
          other.latestGroundSpeedKnots == this.latestGroundSpeedKnots &&
          other.latestIndicatedAirspeedKnots ==
              this.latestIndicatedAirspeedKnots &&
          other.latestMach == this.latestMach &&
          other.latestVerticalRateFeetPerMinute ==
              this.latestVerticalRateFeetPerMinute);
}

class FlightsCompanion extends UpdateCompanion<FlightRow> {
  final Value<int> id;
  final Value<FlightLookupKind> lookupKind;
  final Value<String> lookupValue;
  final Value<String> departureDate;
  final Value<String?> note;
  final Value<String?> hexAddress;
  final Value<String?> expectedCallsign;
  final Value<String?> originIcaoCode;
  final Value<String?> originIataCode;
  final Value<String?> originName;
  final Value<String?> originLocation;
  final Value<double?> originLatitude;
  final Value<double?> originLongitude;
  final Value<String?> destinationIcaoCode;
  final Value<String?> destinationIataCode;
  final Value<String?> destinationName;
  final Value<String?> destinationLocation;
  final Value<double?> destinationLatitude;
  final Value<double?> destinationLongitude;
  final Value<bool> hasBeenAirborne;
  final Value<bool?> lastKnownOnGround;
  final Value<double?> latestLatitude;
  final Value<double?> latestLongitude;
  final Value<int?> latestTimestamp;
  final Value<double?> latestBarometricAltitudeFeet;
  final Value<bool?> latestOnGround;
  final Value<double?> latestGeometricAltitudeFeet;
  final Value<double?> latestTrackDegrees;
  final Value<double?> latestTrueHeadingDegrees;
  final Value<double?> latestGroundSpeedKnots;
  final Value<double?> latestIndicatedAirspeedKnots;
  final Value<double?> latestMach;
  final Value<double?> latestVerticalRateFeetPerMinute;
  const FlightsCompanion({
    this.id = const Value.absent(),
    this.lookupKind = const Value.absent(),
    this.lookupValue = const Value.absent(),
    this.departureDate = const Value.absent(),
    this.note = const Value.absent(),
    this.hexAddress = const Value.absent(),
    this.expectedCallsign = const Value.absent(),
    this.originIcaoCode = const Value.absent(),
    this.originIataCode = const Value.absent(),
    this.originName = const Value.absent(),
    this.originLocation = const Value.absent(),
    this.originLatitude = const Value.absent(),
    this.originLongitude = const Value.absent(),
    this.destinationIcaoCode = const Value.absent(),
    this.destinationIataCode = const Value.absent(),
    this.destinationName = const Value.absent(),
    this.destinationLocation = const Value.absent(),
    this.destinationLatitude = const Value.absent(),
    this.destinationLongitude = const Value.absent(),
    this.hasBeenAirborne = const Value.absent(),
    this.lastKnownOnGround = const Value.absent(),
    this.latestLatitude = const Value.absent(),
    this.latestLongitude = const Value.absent(),
    this.latestTimestamp = const Value.absent(),
    this.latestBarometricAltitudeFeet = const Value.absent(),
    this.latestOnGround = const Value.absent(),
    this.latestGeometricAltitudeFeet = const Value.absent(),
    this.latestTrackDegrees = const Value.absent(),
    this.latestTrueHeadingDegrees = const Value.absent(),
    this.latestGroundSpeedKnots = const Value.absent(),
    this.latestIndicatedAirspeedKnots = const Value.absent(),
    this.latestMach = const Value.absent(),
    this.latestVerticalRateFeetPerMinute = const Value.absent(),
  });
  FlightsCompanion.insert({
    this.id = const Value.absent(),
    required FlightLookupKind lookupKind,
    required String lookupValue,
    required String departureDate,
    this.note = const Value.absent(),
    this.hexAddress = const Value.absent(),
    this.expectedCallsign = const Value.absent(),
    this.originIcaoCode = const Value.absent(),
    this.originIataCode = const Value.absent(),
    this.originName = const Value.absent(),
    this.originLocation = const Value.absent(),
    this.originLatitude = const Value.absent(),
    this.originLongitude = const Value.absent(),
    this.destinationIcaoCode = const Value.absent(),
    this.destinationIataCode = const Value.absent(),
    this.destinationName = const Value.absent(),
    this.destinationLocation = const Value.absent(),
    this.destinationLatitude = const Value.absent(),
    this.destinationLongitude = const Value.absent(),
    this.hasBeenAirborne = const Value.absent(),
    this.lastKnownOnGround = const Value.absent(),
    this.latestLatitude = const Value.absent(),
    this.latestLongitude = const Value.absent(),
    this.latestTimestamp = const Value.absent(),
    this.latestBarometricAltitudeFeet = const Value.absent(),
    this.latestOnGround = const Value.absent(),
    this.latestGeometricAltitudeFeet = const Value.absent(),
    this.latestTrackDegrees = const Value.absent(),
    this.latestTrueHeadingDegrees = const Value.absent(),
    this.latestGroundSpeedKnots = const Value.absent(),
    this.latestIndicatedAirspeedKnots = const Value.absent(),
    this.latestMach = const Value.absent(),
    this.latestVerticalRateFeetPerMinute = const Value.absent(),
  }) : lookupKind = Value(lookupKind),
       lookupValue = Value(lookupValue),
       departureDate = Value(departureDate);
  static Insertable<FlightRow> custom({
    Expression<int>? id,
    Expression<String>? lookupKind,
    Expression<String>? lookupValue,
    Expression<String>? departureDate,
    Expression<String>? note,
    Expression<String>? hexAddress,
    Expression<String>? expectedCallsign,
    Expression<String>? originIcaoCode,
    Expression<String>? originIataCode,
    Expression<String>? originName,
    Expression<String>? originLocation,
    Expression<double>? originLatitude,
    Expression<double>? originLongitude,
    Expression<String>? destinationIcaoCode,
    Expression<String>? destinationIataCode,
    Expression<String>? destinationName,
    Expression<String>? destinationLocation,
    Expression<double>? destinationLatitude,
    Expression<double>? destinationLongitude,
    Expression<bool>? hasBeenAirborne,
    Expression<bool>? lastKnownOnGround,
    Expression<double>? latestLatitude,
    Expression<double>? latestLongitude,
    Expression<int>? latestTimestamp,
    Expression<double>? latestBarometricAltitudeFeet,
    Expression<bool>? latestOnGround,
    Expression<double>? latestGeometricAltitudeFeet,
    Expression<double>? latestTrackDegrees,
    Expression<double>? latestTrueHeadingDegrees,
    Expression<double>? latestGroundSpeedKnots,
    Expression<double>? latestIndicatedAirspeedKnots,
    Expression<double>? latestMach,
    Expression<double>? latestVerticalRateFeetPerMinute,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lookupKind != null) 'lookup_kind': lookupKind,
      if (lookupValue != null) 'lookup_value': lookupValue,
      if (departureDate != null) 'departure_date': departureDate,
      if (note != null) 'note': note,
      if (hexAddress != null) 'hex_address': hexAddress,
      if (expectedCallsign != null) 'expected_callsign': expectedCallsign,
      if (originIcaoCode != null) 'origin_icao_code': originIcaoCode,
      if (originIataCode != null) 'origin_iata_code': originIataCode,
      if (originName != null) 'origin_name': originName,
      if (originLocation != null) 'origin_location': originLocation,
      if (originLatitude != null) 'origin_latitude': originLatitude,
      if (originLongitude != null) 'origin_longitude': originLongitude,
      if (destinationIcaoCode != null)
        'destination_icao_code': destinationIcaoCode,
      if (destinationIataCode != null)
        'destination_iata_code': destinationIataCode,
      if (destinationName != null) 'destination_name': destinationName,
      if (destinationLocation != null)
        'destination_location': destinationLocation,
      if (destinationLatitude != null)
        'destination_latitude': destinationLatitude,
      if (destinationLongitude != null)
        'destination_longitude': destinationLongitude,
      if (hasBeenAirborne != null) 'has_been_airborne': hasBeenAirborne,
      if (lastKnownOnGround != null) 'last_known_on_ground': lastKnownOnGround,
      if (latestLatitude != null) 'latest_latitude': latestLatitude,
      if (latestLongitude != null) 'latest_longitude': latestLongitude,
      if (latestTimestamp != null) 'latest_timestamp': latestTimestamp,
      if (latestBarometricAltitudeFeet != null)
        'latest_barometric_altitude_feet': latestBarometricAltitudeFeet,
      if (latestOnGround != null) 'latest_on_ground': latestOnGround,
      if (latestGeometricAltitudeFeet != null)
        'latest_geometric_altitude_feet': latestGeometricAltitudeFeet,
      if (latestTrackDegrees != null)
        'latest_track_degrees': latestTrackDegrees,
      if (latestTrueHeadingDegrees != null)
        'latest_true_heading_degrees': latestTrueHeadingDegrees,
      if (latestGroundSpeedKnots != null)
        'latest_ground_speed_knots': latestGroundSpeedKnots,
      if (latestIndicatedAirspeedKnots != null)
        'latest_indicated_airspeed_knots': latestIndicatedAirspeedKnots,
      if (latestMach != null) 'latest_mach': latestMach,
      if (latestVerticalRateFeetPerMinute != null)
        'latest_vertical_rate_feet_per_minute': latestVerticalRateFeetPerMinute,
    });
  }

  FlightsCompanion copyWith({
    Value<int>? id,
    Value<FlightLookupKind>? lookupKind,
    Value<String>? lookupValue,
    Value<String>? departureDate,
    Value<String?>? note,
    Value<String?>? hexAddress,
    Value<String?>? expectedCallsign,
    Value<String?>? originIcaoCode,
    Value<String?>? originIataCode,
    Value<String?>? originName,
    Value<String?>? originLocation,
    Value<double?>? originLatitude,
    Value<double?>? originLongitude,
    Value<String?>? destinationIcaoCode,
    Value<String?>? destinationIataCode,
    Value<String?>? destinationName,
    Value<String?>? destinationLocation,
    Value<double?>? destinationLatitude,
    Value<double?>? destinationLongitude,
    Value<bool>? hasBeenAirborne,
    Value<bool?>? lastKnownOnGround,
    Value<double?>? latestLatitude,
    Value<double?>? latestLongitude,
    Value<int?>? latestTimestamp,
    Value<double?>? latestBarometricAltitudeFeet,
    Value<bool?>? latestOnGround,
    Value<double?>? latestGeometricAltitudeFeet,
    Value<double?>? latestTrackDegrees,
    Value<double?>? latestTrueHeadingDegrees,
    Value<double?>? latestGroundSpeedKnots,
    Value<double?>? latestIndicatedAirspeedKnots,
    Value<double?>? latestMach,
    Value<double?>? latestVerticalRateFeetPerMinute,
  }) {
    return FlightsCompanion(
      id: id ?? this.id,
      lookupKind: lookupKind ?? this.lookupKind,
      lookupValue: lookupValue ?? this.lookupValue,
      departureDate: departureDate ?? this.departureDate,
      note: note ?? this.note,
      hexAddress: hexAddress ?? this.hexAddress,
      expectedCallsign: expectedCallsign ?? this.expectedCallsign,
      originIcaoCode: originIcaoCode ?? this.originIcaoCode,
      originIataCode: originIataCode ?? this.originIataCode,
      originName: originName ?? this.originName,
      originLocation: originLocation ?? this.originLocation,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      destinationIcaoCode: destinationIcaoCode ?? this.destinationIcaoCode,
      destinationIataCode: destinationIataCode ?? this.destinationIataCode,
      destinationName: destinationName ?? this.destinationName,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      hasBeenAirborne: hasBeenAirborne ?? this.hasBeenAirborne,
      lastKnownOnGround: lastKnownOnGround ?? this.lastKnownOnGround,
      latestLatitude: latestLatitude ?? this.latestLatitude,
      latestLongitude: latestLongitude ?? this.latestLongitude,
      latestTimestamp: latestTimestamp ?? this.latestTimestamp,
      latestBarometricAltitudeFeet:
          latestBarometricAltitudeFeet ?? this.latestBarometricAltitudeFeet,
      latestOnGround: latestOnGround ?? this.latestOnGround,
      latestGeometricAltitudeFeet:
          latestGeometricAltitudeFeet ?? this.latestGeometricAltitudeFeet,
      latestTrackDegrees: latestTrackDegrees ?? this.latestTrackDegrees,
      latestTrueHeadingDegrees:
          latestTrueHeadingDegrees ?? this.latestTrueHeadingDegrees,
      latestGroundSpeedKnots:
          latestGroundSpeedKnots ?? this.latestGroundSpeedKnots,
      latestIndicatedAirspeedKnots:
          latestIndicatedAirspeedKnots ?? this.latestIndicatedAirspeedKnots,
      latestMach: latestMach ?? this.latestMach,
      latestVerticalRateFeetPerMinute:
          latestVerticalRateFeetPerMinute ??
          this.latestVerticalRateFeetPerMinute,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lookupKind.present) {
      map['lookup_kind'] = Variable<String>(
        $FlightsTable.$converterlookupKind.toSql(lookupKind.value),
      );
    }
    if (lookupValue.present) {
      map['lookup_value'] = Variable<String>(lookupValue.value);
    }
    if (departureDate.present) {
      map['departure_date'] = Variable<String>(departureDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (hexAddress.present) {
      map['hex_address'] = Variable<String>(hexAddress.value);
    }
    if (expectedCallsign.present) {
      map['expected_callsign'] = Variable<String>(expectedCallsign.value);
    }
    if (originIcaoCode.present) {
      map['origin_icao_code'] = Variable<String>(originIcaoCode.value);
    }
    if (originIataCode.present) {
      map['origin_iata_code'] = Variable<String>(originIataCode.value);
    }
    if (originName.present) {
      map['origin_name'] = Variable<String>(originName.value);
    }
    if (originLocation.present) {
      map['origin_location'] = Variable<String>(originLocation.value);
    }
    if (originLatitude.present) {
      map['origin_latitude'] = Variable<double>(originLatitude.value);
    }
    if (originLongitude.present) {
      map['origin_longitude'] = Variable<double>(originLongitude.value);
    }
    if (destinationIcaoCode.present) {
      map['destination_icao_code'] = Variable<String>(
        destinationIcaoCode.value,
      );
    }
    if (destinationIataCode.present) {
      map['destination_iata_code'] = Variable<String>(
        destinationIataCode.value,
      );
    }
    if (destinationName.present) {
      map['destination_name'] = Variable<String>(destinationName.value);
    }
    if (destinationLocation.present) {
      map['destination_location'] = Variable<String>(destinationLocation.value);
    }
    if (destinationLatitude.present) {
      map['destination_latitude'] = Variable<double>(destinationLatitude.value);
    }
    if (destinationLongitude.present) {
      map['destination_longitude'] = Variable<double>(
        destinationLongitude.value,
      );
    }
    if (hasBeenAirborne.present) {
      map['has_been_airborne'] = Variable<bool>(hasBeenAirborne.value);
    }
    if (lastKnownOnGround.present) {
      map['last_known_on_ground'] = Variable<bool>(lastKnownOnGround.value);
    }
    if (latestLatitude.present) {
      map['latest_latitude'] = Variable<double>(latestLatitude.value);
    }
    if (latestLongitude.present) {
      map['latest_longitude'] = Variable<double>(latestLongitude.value);
    }
    if (latestTimestamp.present) {
      map['latest_timestamp'] = Variable<int>(latestTimestamp.value);
    }
    if (latestBarometricAltitudeFeet.present) {
      map['latest_barometric_altitude_feet'] = Variable<double>(
        latestBarometricAltitudeFeet.value,
      );
    }
    if (latestOnGround.present) {
      map['latest_on_ground'] = Variable<bool>(latestOnGround.value);
    }
    if (latestGeometricAltitudeFeet.present) {
      map['latest_geometric_altitude_feet'] = Variable<double>(
        latestGeometricAltitudeFeet.value,
      );
    }
    if (latestTrackDegrees.present) {
      map['latest_track_degrees'] = Variable<double>(latestTrackDegrees.value);
    }
    if (latestTrueHeadingDegrees.present) {
      map['latest_true_heading_degrees'] = Variable<double>(
        latestTrueHeadingDegrees.value,
      );
    }
    if (latestGroundSpeedKnots.present) {
      map['latest_ground_speed_knots'] = Variable<double>(
        latestGroundSpeedKnots.value,
      );
    }
    if (latestIndicatedAirspeedKnots.present) {
      map['latest_indicated_airspeed_knots'] = Variable<double>(
        latestIndicatedAirspeedKnots.value,
      );
    }
    if (latestMach.present) {
      map['latest_mach'] = Variable<double>(latestMach.value);
    }
    if (latestVerticalRateFeetPerMinute.present) {
      map['latest_vertical_rate_feet_per_minute'] = Variable<double>(
        latestVerticalRateFeetPerMinute.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlightsCompanion(')
          ..write('id: $id, ')
          ..write('lookupKind: $lookupKind, ')
          ..write('lookupValue: $lookupValue, ')
          ..write('departureDate: $departureDate, ')
          ..write('note: $note, ')
          ..write('hexAddress: $hexAddress, ')
          ..write('expectedCallsign: $expectedCallsign, ')
          ..write('originIcaoCode: $originIcaoCode, ')
          ..write('originIataCode: $originIataCode, ')
          ..write('originName: $originName, ')
          ..write('originLocation: $originLocation, ')
          ..write('originLatitude: $originLatitude, ')
          ..write('originLongitude: $originLongitude, ')
          ..write('destinationIcaoCode: $destinationIcaoCode, ')
          ..write('destinationIataCode: $destinationIataCode, ')
          ..write('destinationName: $destinationName, ')
          ..write('destinationLocation: $destinationLocation, ')
          ..write('destinationLatitude: $destinationLatitude, ')
          ..write('destinationLongitude: $destinationLongitude, ')
          ..write('hasBeenAirborne: $hasBeenAirborne, ')
          ..write('lastKnownOnGround: $lastKnownOnGround, ')
          ..write('latestLatitude: $latestLatitude, ')
          ..write('latestLongitude: $latestLongitude, ')
          ..write('latestTimestamp: $latestTimestamp, ')
          ..write(
            'latestBarometricAltitudeFeet: $latestBarometricAltitudeFeet, ',
          )
          ..write('latestOnGround: $latestOnGround, ')
          ..write('latestGeometricAltitudeFeet: $latestGeometricAltitudeFeet, ')
          ..write('latestTrackDegrees: $latestTrackDegrees, ')
          ..write('latestTrueHeadingDegrees: $latestTrueHeadingDegrees, ')
          ..write('latestGroundSpeedKnots: $latestGroundSpeedKnots, ')
          ..write(
            'latestIndicatedAirspeedKnots: $latestIndicatedAirspeedKnots, ',
          )
          ..write('latestMach: $latestMach, ')
          ..write(
            'latestVerticalRateFeetPerMinute: $latestVerticalRateFeetPerMinute',
          )
          ..write(')'))
        .toString();
  }
}

class $TrailPointsTable extends TrailPoints
    with TableInfo<$TrailPointsTable, TrailPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flightIdMeta = const VerificationMeta(
    'flightId',
  );
  @override
  late final GeneratedColumn<int> flightId = GeneratedColumn<int>(
    'flight_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flights (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceId, String> sourceId =
      GeneratedColumn<String>(
        'source_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceId>($TrailPointsTable.$convertersourceId);
  @override
  List<GeneratedColumn> get $columns => [
    flightId,
    timestamp,
    latitude,
    longitude,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flight_id')) {
      context.handle(
        _flightIdMeta,
        flightId.isAcceptableOrUnknown(data['flight_id']!, _flightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_flightIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {flightId, timestamp};
  @override
  TrailPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailPointRow(
      flightId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flight_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      sourceId: $TrailPointsTable.$convertersourceId.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_id'],
        )!,
      ),
    );
  }

  @override
  $TrailPointsTable createAlias(String alias) {
    return $TrailPointsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceId, String, String> $convertersourceId =
      const EnumNameConverter<SourceId>(SourceId.values);
}

class TrailPointRow extends DataClass implements Insertable<TrailPointRow> {
  final int flightId;
  final int timestamp;
  final double latitude;
  final double longitude;
  final SourceId sourceId;
  const TrailPointRow({
    required this.flightId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['flight_id'] = Variable<int>(flightId);
    map['timestamp'] = Variable<int>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    {
      map['source_id'] = Variable<String>(
        $TrailPointsTable.$convertersourceId.toSql(sourceId),
      );
    }
    return map;
  }

  TrailPointsCompanion toCompanion(bool nullToAbsent) {
    return TrailPointsCompanion(
      flightId: Value(flightId),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      sourceId: Value(sourceId),
    );
  }

  factory TrailPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailPointRow(
      flightId: serializer.fromJson<int>(json['flightId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      sourceId: $TrailPointsTable.$convertersourceId.fromJson(
        serializer.fromJson<String>(json['sourceId']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'flightId': serializer.toJson<int>(flightId),
      'timestamp': serializer.toJson<int>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'sourceId': serializer.toJson<String>(
        $TrailPointsTable.$convertersourceId.toJson(sourceId),
      ),
    };
  }

  TrailPointRow copyWith({
    int? flightId,
    int? timestamp,
    double? latitude,
    double? longitude,
    SourceId? sourceId,
  }) => TrailPointRow(
    flightId: flightId ?? this.flightId,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    sourceId: sourceId ?? this.sourceId,
  );
  TrailPointRow copyWithCompanion(TrailPointsCompanion data) {
    return TrailPointRow(
      flightId: data.flightId.present ? data.flightId.value : this.flightId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailPointRow(')
          ..write('flightId: $flightId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(flightId, timestamp, latitude, longitude, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailPointRow &&
          other.flightId == this.flightId &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.sourceId == this.sourceId);
}

class TrailPointsCompanion extends UpdateCompanion<TrailPointRow> {
  final Value<int> flightId;
  final Value<int> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<SourceId> sourceId;
  final Value<int> rowid;
  const TrailPointsCompanion({
    this.flightId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailPointsCompanion.insert({
    required int flightId,
    required int timestamp,
    required double latitude,
    required double longitude,
    required SourceId sourceId,
    this.rowid = const Value.absent(),
  }) : flightId = Value(flightId),
       timestamp = Value(timestamp),
       latitude = Value(latitude),
       longitude = Value(longitude),
       sourceId = Value(sourceId);
  static Insertable<TrailPointRow> custom({
    Expression<int>? flightId,
    Expression<int>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (flightId != null) 'flight_id': flightId,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailPointsCompanion copyWith({
    Value<int>? flightId,
    Value<int>? timestamp,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<SourceId>? sourceId,
    Value<int>? rowid,
  }) {
    return TrailPointsCompanion(
      flightId: flightId ?? this.flightId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (flightId.present) {
      map['flight_id'] = Variable<int>(flightId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(
        $TrailPointsTable.$convertersourceId.toSql(sourceId.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailPointsCompanion(')
          ..write('flightId: $flightId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FlightsTable flights = $FlightsTable(this);
  late final $TrailPointsTable trailPoints = $TrailPointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [flights, trailPoints];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flights',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trail_points', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FlightsTableCreateCompanionBuilder =
    FlightsCompanion Function({
      Value<int> id,
      required FlightLookupKind lookupKind,
      required String lookupValue,
      required String departureDate,
      Value<String?> note,
      Value<String?> hexAddress,
      Value<String?> expectedCallsign,
      Value<String?> originIcaoCode,
      Value<String?> originIataCode,
      Value<String?> originName,
      Value<String?> originLocation,
      Value<double?> originLatitude,
      Value<double?> originLongitude,
      Value<String?> destinationIcaoCode,
      Value<String?> destinationIataCode,
      Value<String?> destinationName,
      Value<String?> destinationLocation,
      Value<double?> destinationLatitude,
      Value<double?> destinationLongitude,
      Value<bool> hasBeenAirborne,
      Value<bool?> lastKnownOnGround,
      Value<double?> latestLatitude,
      Value<double?> latestLongitude,
      Value<int?> latestTimestamp,
      Value<double?> latestBarometricAltitudeFeet,
      Value<bool?> latestOnGround,
      Value<double?> latestGeometricAltitudeFeet,
      Value<double?> latestTrackDegrees,
      Value<double?> latestTrueHeadingDegrees,
      Value<double?> latestGroundSpeedKnots,
      Value<double?> latestIndicatedAirspeedKnots,
      Value<double?> latestMach,
      Value<double?> latestVerticalRateFeetPerMinute,
    });
typedef $$FlightsTableUpdateCompanionBuilder =
    FlightsCompanion Function({
      Value<int> id,
      Value<FlightLookupKind> lookupKind,
      Value<String> lookupValue,
      Value<String> departureDate,
      Value<String?> note,
      Value<String?> hexAddress,
      Value<String?> expectedCallsign,
      Value<String?> originIcaoCode,
      Value<String?> originIataCode,
      Value<String?> originName,
      Value<String?> originLocation,
      Value<double?> originLatitude,
      Value<double?> originLongitude,
      Value<String?> destinationIcaoCode,
      Value<String?> destinationIataCode,
      Value<String?> destinationName,
      Value<String?> destinationLocation,
      Value<double?> destinationLatitude,
      Value<double?> destinationLongitude,
      Value<bool> hasBeenAirborne,
      Value<bool?> lastKnownOnGround,
      Value<double?> latestLatitude,
      Value<double?> latestLongitude,
      Value<int?> latestTimestamp,
      Value<double?> latestBarometricAltitudeFeet,
      Value<bool?> latestOnGround,
      Value<double?> latestGeometricAltitudeFeet,
      Value<double?> latestTrackDegrees,
      Value<double?> latestTrueHeadingDegrees,
      Value<double?> latestGroundSpeedKnots,
      Value<double?> latestIndicatedAirspeedKnots,
      Value<double?> latestMach,
      Value<double?> latestVerticalRateFeetPerMinute,
    });

final class $$FlightsTableReferences
    extends BaseReferences<_$AppDatabase, $FlightsTable, FlightRow> {
  $$FlightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrailPointsTable, List<TrailPointRow>>
  _trailPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trailPoints,
    aliasName: 'flights__id__trail_points__flight_id',
  );

  $$TrailPointsTableProcessedTableManager get trailPointsRefs {
    final manager = $$TrailPointsTableTableManager(
      $_db,
      $_db.trailPoints,
    ).filter((f) => f.flightId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trailPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlightsTableFilterComposer
    extends Composer<_$AppDatabase, $FlightsTable> {
  $$FlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FlightLookupKind, FlightLookupKind, String>
  get lookupKind => $composableBuilder(
    column: $table.lookupKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get lookupValue => $composableBuilder(
    column: $table.lookupValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departureDate => $composableBuilder(
    column: $table.departureDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hexAddress => $composableBuilder(
    column: $table.hexAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedCallsign => $composableBuilder(
    column: $table.expectedCallsign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originIcaoCode => $composableBuilder(
    column: $table.originIcaoCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originIataCode => $composableBuilder(
    column: $table.originIataCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originLocation => $composableBuilder(
    column: $table.originLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originLatitude => $composableBuilder(
    column: $table.originLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originLongitude => $composableBuilder(
    column: $table.originLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationIcaoCode => $composableBuilder(
    column: $table.destinationIcaoCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationIataCode => $composableBuilder(
    column: $table.destinationIataCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationLocation => $composableBuilder(
    column: $table.destinationLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get destinationLatitude => $composableBuilder(
    column: $table.destinationLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get destinationLongitude => $composableBuilder(
    column: $table.destinationLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasBeenAirborne => $composableBuilder(
    column: $table.hasBeenAirborne,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastKnownOnGround => $composableBuilder(
    column: $table.lastKnownOnGround,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestLatitude => $composableBuilder(
    column: $table.latestLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestLongitude => $composableBuilder(
    column: $table.latestLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestTimestamp => $composableBuilder(
    column: $table.latestTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestBarometricAltitudeFeet => $composableBuilder(
    column: $table.latestBarometricAltitudeFeet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get latestOnGround => $composableBuilder(
    column: $table.latestOnGround,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestGeometricAltitudeFeet => $composableBuilder(
    column: $table.latestGeometricAltitudeFeet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestTrackDegrees => $composableBuilder(
    column: $table.latestTrackDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestTrueHeadingDegrees => $composableBuilder(
    column: $table.latestTrueHeadingDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestGroundSpeedKnots => $composableBuilder(
    column: $table.latestGroundSpeedKnots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestIndicatedAirspeedKnots => $composableBuilder(
    column: $table.latestIndicatedAirspeedKnots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestMach => $composableBuilder(
    column: $table.latestMach,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestVerticalRateFeetPerMinute =>
      $composableBuilder(
        column: $table.latestVerticalRateFeetPerMinute,
        builder: (column) => ColumnFilters(column),
      );

  Expression<bool> trailPointsRefs(
    Expression<bool> Function($$TrailPointsTableFilterComposer f) f,
  ) {
    final $$TrailPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trailPoints,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrailPointsTableFilterComposer(
            $db: $db,
            $table: $db.trailPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlightsTable> {
  $$FlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lookupKind => $composableBuilder(
    column: $table.lookupKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lookupValue => $composableBuilder(
    column: $table.lookupValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departureDate => $composableBuilder(
    column: $table.departureDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hexAddress => $composableBuilder(
    column: $table.hexAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedCallsign => $composableBuilder(
    column: $table.expectedCallsign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originIcaoCode => $composableBuilder(
    column: $table.originIcaoCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originIataCode => $composableBuilder(
    column: $table.originIataCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originLocation => $composableBuilder(
    column: $table.originLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originLatitude => $composableBuilder(
    column: $table.originLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originLongitude => $composableBuilder(
    column: $table.originLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationIcaoCode => $composableBuilder(
    column: $table.destinationIcaoCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationIataCode => $composableBuilder(
    column: $table.destinationIataCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationLocation => $composableBuilder(
    column: $table.destinationLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get destinationLatitude => $composableBuilder(
    column: $table.destinationLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get destinationLongitude => $composableBuilder(
    column: $table.destinationLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasBeenAirborne => $composableBuilder(
    column: $table.hasBeenAirborne,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastKnownOnGround => $composableBuilder(
    column: $table.lastKnownOnGround,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestLatitude => $composableBuilder(
    column: $table.latestLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestLongitude => $composableBuilder(
    column: $table.latestLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestTimestamp => $composableBuilder(
    column: $table.latestTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestBarometricAltitudeFeet =>
      $composableBuilder(
        column: $table.latestBarometricAltitudeFeet,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get latestOnGround => $composableBuilder(
    column: $table.latestOnGround,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestGeometricAltitudeFeet => $composableBuilder(
    column: $table.latestGeometricAltitudeFeet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestTrackDegrees => $composableBuilder(
    column: $table.latestTrackDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestTrueHeadingDegrees => $composableBuilder(
    column: $table.latestTrueHeadingDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestGroundSpeedKnots => $composableBuilder(
    column: $table.latestGroundSpeedKnots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestIndicatedAirspeedKnots =>
      $composableBuilder(
        column: $table.latestIndicatedAirspeedKnots,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<double> get latestMach => $composableBuilder(
    column: $table.latestMach,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestVerticalRateFeetPerMinute =>
      $composableBuilder(
        column: $table.latestVerticalRateFeetPerMinute,
        builder: (column) => ColumnOrderings(column),
      );
}

class $$FlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlightsTable> {
  $$FlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FlightLookupKind, String> get lookupKind =>
      $composableBuilder(
        column: $table.lookupKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get lookupValue => $composableBuilder(
    column: $table.lookupValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get departureDate => $composableBuilder(
    column: $table.departureDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get hexAddress => $composableBuilder(
    column: $table.hexAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedCallsign => $composableBuilder(
    column: $table.expectedCallsign,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originIcaoCode => $composableBuilder(
    column: $table.originIcaoCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originIataCode => $composableBuilder(
    column: $table.originIataCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originLocation => $composableBuilder(
    column: $table.originLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get originLatitude => $composableBuilder(
    column: $table.originLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get originLongitude => $composableBuilder(
    column: $table.originLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationIcaoCode => $composableBuilder(
    column: $table.destinationIcaoCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationIataCode => $composableBuilder(
    column: $table.destinationIataCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationName => $composableBuilder(
    column: $table.destinationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationLocation => $composableBuilder(
    column: $table.destinationLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get destinationLatitude => $composableBuilder(
    column: $table.destinationLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get destinationLongitude => $composableBuilder(
    column: $table.destinationLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasBeenAirborne => $composableBuilder(
    column: $table.hasBeenAirborne,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastKnownOnGround => $composableBuilder(
    column: $table.lastKnownOnGround,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestLatitude => $composableBuilder(
    column: $table.latestLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestLongitude => $composableBuilder(
    column: $table.latestLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestTimestamp => $composableBuilder(
    column: $table.latestTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestBarometricAltitudeFeet =>
      $composableBuilder(
        column: $table.latestBarometricAltitudeFeet,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get latestOnGround => $composableBuilder(
    column: $table.latestOnGround,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestGeometricAltitudeFeet => $composableBuilder(
    column: $table.latestGeometricAltitudeFeet,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestTrackDegrees => $composableBuilder(
    column: $table.latestTrackDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestTrueHeadingDegrees => $composableBuilder(
    column: $table.latestTrueHeadingDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestGroundSpeedKnots => $composableBuilder(
    column: $table.latestGroundSpeedKnots,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestIndicatedAirspeedKnots =>
      $composableBuilder(
        column: $table.latestIndicatedAirspeedKnots,
        builder: (column) => column,
      );

  GeneratedColumn<double> get latestMach => $composableBuilder(
    column: $table.latestMach,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestVerticalRateFeetPerMinute =>
      $composableBuilder(
        column: $table.latestVerticalRateFeetPerMinute,
        builder: (column) => column,
      );

  Expression<T> trailPointsRefs<T extends Object>(
    Expression<T> Function($$TrailPointsTableAnnotationComposer a) f,
  ) {
    final $$TrailPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trailPoints,
      getReferencedColumn: (t) => t.flightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrailPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trailPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlightsTable,
          FlightRow,
          $$FlightsTableFilterComposer,
          $$FlightsTableOrderingComposer,
          $$FlightsTableAnnotationComposer,
          $$FlightsTableCreateCompanionBuilder,
          $$FlightsTableUpdateCompanionBuilder,
          (FlightRow, $$FlightsTableReferences),
          FlightRow,
          PrefetchHooks Function({bool trailPointsRefs})
        > {
  $$FlightsTableTableManager(_$AppDatabase db, $FlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<FlightLookupKind> lookupKind = const Value.absent(),
                Value<String> lookupValue = const Value.absent(),
                Value<String> departureDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> hexAddress = const Value.absent(),
                Value<String?> expectedCallsign = const Value.absent(),
                Value<String?> originIcaoCode = const Value.absent(),
                Value<String?> originIataCode = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<String?> originLocation = const Value.absent(),
                Value<double?> originLatitude = const Value.absent(),
                Value<double?> originLongitude = const Value.absent(),
                Value<String?> destinationIcaoCode = const Value.absent(),
                Value<String?> destinationIataCode = const Value.absent(),
                Value<String?> destinationName = const Value.absent(),
                Value<String?> destinationLocation = const Value.absent(),
                Value<double?> destinationLatitude = const Value.absent(),
                Value<double?> destinationLongitude = const Value.absent(),
                Value<bool> hasBeenAirborne = const Value.absent(),
                Value<bool?> lastKnownOnGround = const Value.absent(),
                Value<double?> latestLatitude = const Value.absent(),
                Value<double?> latestLongitude = const Value.absent(),
                Value<int?> latestTimestamp = const Value.absent(),
                Value<double?> latestBarometricAltitudeFeet =
                    const Value.absent(),
                Value<bool?> latestOnGround = const Value.absent(),
                Value<double?> latestGeometricAltitudeFeet =
                    const Value.absent(),
                Value<double?> latestTrackDegrees = const Value.absent(),
                Value<double?> latestTrueHeadingDegrees = const Value.absent(),
                Value<double?> latestGroundSpeedKnots = const Value.absent(),
                Value<double?> latestIndicatedAirspeedKnots =
                    const Value.absent(),
                Value<double?> latestMach = const Value.absent(),
                Value<double?> latestVerticalRateFeetPerMinute =
                    const Value.absent(),
              }) => FlightsCompanion(
                id: id,
                lookupKind: lookupKind,
                lookupValue: lookupValue,
                departureDate: departureDate,
                note: note,
                hexAddress: hexAddress,
                expectedCallsign: expectedCallsign,
                originIcaoCode: originIcaoCode,
                originIataCode: originIataCode,
                originName: originName,
                originLocation: originLocation,
                originLatitude: originLatitude,
                originLongitude: originLongitude,
                destinationIcaoCode: destinationIcaoCode,
                destinationIataCode: destinationIataCode,
                destinationName: destinationName,
                destinationLocation: destinationLocation,
                destinationLatitude: destinationLatitude,
                destinationLongitude: destinationLongitude,
                hasBeenAirborne: hasBeenAirborne,
                lastKnownOnGround: lastKnownOnGround,
                latestLatitude: latestLatitude,
                latestLongitude: latestLongitude,
                latestTimestamp: latestTimestamp,
                latestBarometricAltitudeFeet: latestBarometricAltitudeFeet,
                latestOnGround: latestOnGround,
                latestGeometricAltitudeFeet: latestGeometricAltitudeFeet,
                latestTrackDegrees: latestTrackDegrees,
                latestTrueHeadingDegrees: latestTrueHeadingDegrees,
                latestGroundSpeedKnots: latestGroundSpeedKnots,
                latestIndicatedAirspeedKnots: latestIndicatedAirspeedKnots,
                latestMach: latestMach,
                latestVerticalRateFeetPerMinute:
                    latestVerticalRateFeetPerMinute,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required FlightLookupKind lookupKind,
                required String lookupValue,
                required String departureDate,
                Value<String?> note = const Value.absent(),
                Value<String?> hexAddress = const Value.absent(),
                Value<String?> expectedCallsign = const Value.absent(),
                Value<String?> originIcaoCode = const Value.absent(),
                Value<String?> originIataCode = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<String?> originLocation = const Value.absent(),
                Value<double?> originLatitude = const Value.absent(),
                Value<double?> originLongitude = const Value.absent(),
                Value<String?> destinationIcaoCode = const Value.absent(),
                Value<String?> destinationIataCode = const Value.absent(),
                Value<String?> destinationName = const Value.absent(),
                Value<String?> destinationLocation = const Value.absent(),
                Value<double?> destinationLatitude = const Value.absent(),
                Value<double?> destinationLongitude = const Value.absent(),
                Value<bool> hasBeenAirborne = const Value.absent(),
                Value<bool?> lastKnownOnGround = const Value.absent(),
                Value<double?> latestLatitude = const Value.absent(),
                Value<double?> latestLongitude = const Value.absent(),
                Value<int?> latestTimestamp = const Value.absent(),
                Value<double?> latestBarometricAltitudeFeet =
                    const Value.absent(),
                Value<bool?> latestOnGround = const Value.absent(),
                Value<double?> latestGeometricAltitudeFeet =
                    const Value.absent(),
                Value<double?> latestTrackDegrees = const Value.absent(),
                Value<double?> latestTrueHeadingDegrees = const Value.absent(),
                Value<double?> latestGroundSpeedKnots = const Value.absent(),
                Value<double?> latestIndicatedAirspeedKnots =
                    const Value.absent(),
                Value<double?> latestMach = const Value.absent(),
                Value<double?> latestVerticalRateFeetPerMinute =
                    const Value.absent(),
              }) => FlightsCompanion.insert(
                id: id,
                lookupKind: lookupKind,
                lookupValue: lookupValue,
                departureDate: departureDate,
                note: note,
                hexAddress: hexAddress,
                expectedCallsign: expectedCallsign,
                originIcaoCode: originIcaoCode,
                originIataCode: originIataCode,
                originName: originName,
                originLocation: originLocation,
                originLatitude: originLatitude,
                originLongitude: originLongitude,
                destinationIcaoCode: destinationIcaoCode,
                destinationIataCode: destinationIataCode,
                destinationName: destinationName,
                destinationLocation: destinationLocation,
                destinationLatitude: destinationLatitude,
                destinationLongitude: destinationLongitude,
                hasBeenAirborne: hasBeenAirborne,
                lastKnownOnGround: lastKnownOnGround,
                latestLatitude: latestLatitude,
                latestLongitude: latestLongitude,
                latestTimestamp: latestTimestamp,
                latestBarometricAltitudeFeet: latestBarometricAltitudeFeet,
                latestOnGround: latestOnGround,
                latestGeometricAltitudeFeet: latestGeometricAltitudeFeet,
                latestTrackDegrees: latestTrackDegrees,
                latestTrueHeadingDegrees: latestTrueHeadingDegrees,
                latestGroundSpeedKnots: latestGroundSpeedKnots,
                latestIndicatedAirspeedKnots: latestIndicatedAirspeedKnots,
                latestMach: latestMach,
                latestVerticalRateFeetPerMinute:
                    latestVerticalRateFeetPerMinute,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trailPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trailPointsRefs) db.trailPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trailPointsRefs)
                    await $_getPrefetchedData<
                      FlightRow,
                      $FlightsTable,
                      TrailPointRow
                    >(
                      currentTable: table,
                      referencedTable: $$FlightsTableReferences
                          ._trailPointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FlightsTableReferences(
                        db,
                        table,
                        p0,
                      ).trailPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.flightId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlightsTable,
      FlightRow,
      $$FlightsTableFilterComposer,
      $$FlightsTableOrderingComposer,
      $$FlightsTableAnnotationComposer,
      $$FlightsTableCreateCompanionBuilder,
      $$FlightsTableUpdateCompanionBuilder,
      (FlightRow, $$FlightsTableReferences),
      FlightRow,
      PrefetchHooks Function({bool trailPointsRefs})
    >;
typedef $$TrailPointsTableCreateCompanionBuilder =
    TrailPointsCompanion Function({
      required int flightId,
      required int timestamp,
      required double latitude,
      required double longitude,
      required SourceId sourceId,
      Value<int> rowid,
    });
typedef $$TrailPointsTableUpdateCompanionBuilder =
    TrailPointsCompanion Function({
      Value<int> flightId,
      Value<int> timestamp,
      Value<double> latitude,
      Value<double> longitude,
      Value<SourceId> sourceId,
      Value<int> rowid,
    });

final class $$TrailPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrailPointsTable, TrailPointRow> {
  $$TrailPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FlightsTable _flightIdTable(_$AppDatabase db) =>
      db.flights.createAlias('trail_points__flight_id__flights__id');

  $$FlightsTableProcessedTableManager get flightId {
    final $_column = $_itemColumn<int>('flight_id')!;

    final manager = $$FlightsTableTableManager(
      $_db,
      $_db.flights,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrailPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrailPointsTable> {
  $$TrailPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceId, SourceId, String> get sourceId =>
      $composableBuilder(
        column: $table.sourceId,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$FlightsTableFilterComposer get flightId {
    final $$FlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableFilterComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrailPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailPointsTable> {
  $$TrailPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlightsTableOrderingComposer get flightId {
    final $$FlightsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableOrderingComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrailPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailPointsTable> {
  $$TrailPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceId, String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  $$FlightsTableAnnotationComposer get flightId {
    final $$FlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flightId,
      referencedTable: $db.flights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.flights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrailPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailPointsTable,
          TrailPointRow,
          $$TrailPointsTableFilterComposer,
          $$TrailPointsTableOrderingComposer,
          $$TrailPointsTableAnnotationComposer,
          $$TrailPointsTableCreateCompanionBuilder,
          $$TrailPointsTableUpdateCompanionBuilder,
          (TrailPointRow, $$TrailPointsTableReferences),
          TrailPointRow,
          PrefetchHooks Function({bool flightId})
        > {
  $$TrailPointsTableTableManager(_$AppDatabase db, $TrailPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> flightId = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<SourceId> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailPointsCompanion(
                flightId: flightId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int flightId,
                required int timestamp,
                required double latitude,
                required double longitude,
                required SourceId sourceId,
                Value<int> rowid = const Value.absent(),
              }) => TrailPointsCompanion.insert(
                flightId: flightId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrailPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (flightId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.flightId,
                                referencedTable: $$TrailPointsTableReferences
                                    ._flightIdTable(db),
                                referencedColumn: $$TrailPointsTableReferences
                                    ._flightIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrailPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailPointsTable,
      TrailPointRow,
      $$TrailPointsTableFilterComposer,
      $$TrailPointsTableOrderingComposer,
      $$TrailPointsTableAnnotationComposer,
      $$TrailPointsTableCreateCompanionBuilder,
      $$TrailPointsTableUpdateCompanionBuilder,
      (TrailPointRow, $$TrailPointsTableReferences),
      TrailPointRow,
      PrefetchHooks Function({bool flightId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FlightsTableTableManager get flights =>
      $$FlightsTableTableManager(_db, _db.flights);
  $$TrailPointsTableTableManager get trailPoints =>
      $$TrailPointsTableTableManager(_db, _db.trailPoints);
}
