import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/adapters/lookup_result.dart';
import 'package:flugwacht/data/adapters/source_adapter.dart';
import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/lookup/airline_directory.dart';
import 'package:flugwacht/data/lookup/route_lookup.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/persistence/database.dart';
import 'package:flugwacht/data/persistence/flight_repository.dart';
import 'package:flugwacht/data/settings/map_style_setting.dart';
import 'package:flugwacht/data/settings/notification_setting.dart';
import 'package:flugwacht/data/settings/source_setting.dart';
import 'package:flugwacht/data/settings/units_setting.dart';
import 'package:flugwacht/data/vector_tile_source.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/ui/app_router.dart';
import 'package:flugwacht/ui/widgets/map/map_visuals.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:signals/signals.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

const testAirlinesCsv =
    'Code,Name,ICAO,IATA,PositioningFlightPattern,CharterFlightPattern\n'
    'DLH,Lufthansa,DLH,LH,,\n'
    'GEC,Lufthansa Cargo,GEC,LH,,\n'
    'RYR,Ryanair,RYR,FR,,\n';

FlightRepository createTestRepository() {
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  return FlightRepository(database);
}

AirlineDirectory createTestAirlineDirectory() =>
    AirlineDirectory.fromCsv(testAirlinesCsv);

/// A setting on an empty in-memory store, so no test sees what another stored.
Future<SourceSetting> createTestSourceSetting() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final setting = await SourceSetting.load();
  addTearDown(setting.dispose);
  return setting;
}

/// A setting on an empty in-memory store, so no test sees what another stored.
Future<MapStyleSetting> createTestMapStyleSetting() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final setting = await MapStyleSetting.load();
  addTearDown(setting.dispose);
  return setting;
}

/// A setting on an empty in-memory store, so no test sees what another stored.
Future<UnitsSetting> createTestUnitsSetting() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final setting = await UnitsSetting.load();
  addTearDown(setting.dispose);
  return setting;
}

/// A setting on an empty in-memory store, so no test sees what another stored.
Future<NotificationSetting> createTestNotificationSetting() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final setting = await NotificationSetting.load();
  addTearDown(setting.dispose);
  return setting;
}

/// A service that records what the app asked of it instead of talking to the
/// platform, so no test touches the notification plugin.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    NotificationPermission permission = NotificationPermission.notDetermined,
  }) : permission = signal(permission);

  @override
  final Signal<NotificationPermission> permission;

  var permissionRequests = 0;
  var permissionRefreshes = 0;
  final shown = <(FlightNotification, int)>[];
  final scheduled = <(FlightNotification, int, DateTime)>[];
  final cancelled = <(FlightNotification, int)>[];
  final _tappedFlights = StreamController<int>.broadcast();

  @override
  int? launchFlightId;

  @override
  Stream<int> get tappedFlights => _tappedFlights.stream;

  /// Stands in for the user tapping the notification of a flight.
  void tap(int flightId) => _tappedFlights.add(flightId);

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
    permission.value = NotificationPermission.granted;
  }

  @override
  Future<void> refreshPermission() async => permissionRefreshes++;

  @override
  Future<void> show(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
  }) async => shown.add((kind, flightId));

  @override
  Future<void> schedule(
    FlightNotification kind, {
    required int flightId,
    required String title,
    required String body,
    required DateTime at,
  }) async => scheduled.add((kind, flightId, at));

  @override
  Future<void> cancel(FlightNotification kind, {required int flightId}) async =>
      cancelled.add((kind, flightId));

  void dispose() {
    permission.dispose();
    unawaited(_tappedFlights.close());
  }
}

/// Switch states without a preference store behind them, so a synchronous test
/// can set them up in one line.
class FakeNotificationSetting implements NotificationSetting {
  FakeNotificationSetting({
    this.enabled = const {
      FlightNotification.departed,
      FlightNotification.arrivingSoon,
      FlightNotification.landed,
    },
    this.wasOffered = false,
  });

  Set<FlightNotification> enabled;

  @override
  bool wasOffered;

  @override
  bool isEnabled(FlightNotification kind) => enabled.contains(kind);

  @override
  Future<void> select(
    FlightNotification kind, {
    required bool isEnabled,
  }) async {
    enabled = isEnabled ? {...enabled, kind} : ({...enabled}..remove(kind));
  }

  @override
  Future<void> enableAll() async => enabled = FlightNotification.values.toSet();

  @override
  Future<void> rememberOffer() async => wasOffered = true;

  @override
  void dispose() {}
}

/// Records what the app asked the platform to open, so no test leaves the app
/// for a browser.
class FakeUrlLauncher extends UrlLauncherPlatform {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

FakeUrlLauncher createTestUrlLauncher() {
  final launcher = FakeUrlLauncher();
  final previous = UrlLauncherPlatform.instance;
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = previous);
  return launcher;
}

FakeNotificationService createTestNotificationService({
  NotificationPermission permission = NotificationPermission.notDetermined,
}) {
  final service = FakeNotificationService(permission: permission);
  addTearDown(service.dispose);
  return service;
}

FakeLiveActivityService createTestLiveActivityService() {
  final service = FakeLiveActivityService();
  addTearDown(service.dispose);
  return service;
}

Future<GoRouter> createTestAppRouter({
  FlightRepository? flightRepository,
  NotificationService? notificationService,
}) async => createAppRouter(
  flightRepository: flightRepository ?? createTestRepository(),
  airlineDirectory: createTestAirlineDirectory(),
  routeLookup: FakeRouteLookup(),
  sourceSetting: await createTestSourceSetting(),
  mapStyleSetting: await createTestMapStyleSetting(),
  unitsSetting: await createTestUnitsSetting(),
  notificationSetting: await createTestNotificationSetting(),
  notificationService: notificationService ?? createTestNotificationService(),
  liveActivityService: createTestLiveActivityService(),
  tileSources: testTileSources(),
  packageInfo: testPackageInfo(),
);

PackageInfo testPackageInfo({String version = '1.0.0'}) => PackageInfo(
  appName: 'Flugwacht',
  packageName: 'com.boundfoxstudios.apps.flugwacht',
  version: version,
  buildNumber: '1',
);

/// Tiles from stub providers under a stand-in package name, so no widget test
/// loads a tile over the network — and none writes into a platform directory
/// the test binding does not have.
MapTileSources testTileSources({
  String userAgentPackageName = 'com.boundfoxstudios.apps.flugwacht',
  bool withVectorTiles = false,
}) => MapTileSources(
  userAgentPackageName: userAgentPackageName,
  vectorTileProviders: signal(
    withVectorTiles
        ? TileProviders({
            VectorTileSource.styleSourceName: StubVectorTileProvider(),
          })
        : null,
  ),
  tileProvider: StubTileProvider(),
);

typedef LiveActivityPut = ({String activityId, Map<String, dynamic> data});
typedef LiveActivityEnd = ({String activityId, DateTime? dismissAt});

class FakeLiveActivityService implements LiveActivityService {
  final puts = <LiveActivityPut>[];
  final ends = <LiveActivityEnd>[];
  var running = const <String>[];
  var availabilityRefreshes = 0;

  @override
  final availability = signal(LiveActivityAvailability.enabled);

  final _tappedFlights = StreamController<int>.broadcast();

  @override
  Stream<int> get tappedFlights => _tappedFlights.stream;

  /// Stands in for the user tapping the card of a flight.
  void tap(int flightId) => _tappedFlights.add(flightId);

  void dispose() {
    availability.dispose();
    unawaited(_tappedFlights.close());
  }

  @override
  Future<void> refreshAvailability() async => availabilityRefreshes++;

  @override
  Future<void> put(
    String activityId, {
    required Map<String, dynamic> data,
    required Duration staleIn,
  }) async => puts.add((activityId: activityId, data: data));

  @override
  Future<void> end(String activityId, {DateTime? dismissAt}) async =>
      ends.add((activityId: activityId, dismissAt: dismissAt));

  @override
  Future<List<String>> runningActivityIds() async => running;
}

class FakeFlightRepository implements FlightRepository {
  final _flights = StreamController<List<Flight>>.broadcast();
  final _trails = StreamController<List<TrailPoint>>.broadcast();
  final expiryChecks = <DateTime>[];
  final watchedTrails = <int>[];
  final trackingUpdates = <(int, FlightTracking)>[];
  final trailAppends = <(int, FixPosition, SourceId)>[];
  final identityUpdates = <(int, String?, String?)>[];
  final notificationMarks = <(int, FlightNotification)>[];
  final arrivingSoonSchedules = <int, DateTime>{};
  final deletedFlightIds = <int>[];
  final clearedTrails = <int>[];
  final notificationResets = <int>[];
  final liveActivityIds = <int, String>{};

  /// Holds up the reconcile, so a test can watch what runs while it is still
  /// in flight.
  Completer<void>? pendingReconcile;

  void emit(List<Flight> flights) => _flights.add(flights);

  void emitTrail(List<TrailPoint> trail) => _trails.add(trail);

  void dispose() {
    unawaited(_flights.close());
    unawaited(_trails.close());
  }

  @override
  Stream<List<Flight>> watchFlights() => _flights.stream;

  @override
  Stream<List<TrailPoint>> watchTrail(int flightId) {
    watchedTrails.add(flightId);
    return _trails.stream;
  }

  @override
  Future<void> deleteExpiredFlights(DateTime now) async =>
      expiryChecks.add(now);

  @override
  Future<void> deleteFlight(int flightId) async =>
      deletedFlightIds.add(flightId);

  @override
  Future<void> updateTracking(int flightId, FlightTracking tracking) async =>
      trackingUpdates.add((flightId, tracking));

  @override
  Future<void> appendTrailPoint(
    int flightId,
    FixPosition position,
    SourceId sourceId,
  ) async => trailAppends.add((flightId, position, sourceId));

  @override
  Future<void> clearTrail(int flightId) async => clearedTrails.add(flightId);

  @override
  Future<void> resetNotificationMarkers(int flightId) async {
    notificationResets.add(flightId);
    notificationMarks.removeWhere((mark) => mark.$1 == flightId);
    arrivingSoonSchedules.remove(flightId);
  }

  @override
  Future<void> updateIdentity(
    int flightId, {
    required String? hexAddress,
    required String? expectedCallsign,
  }) async => identityUpdates.add((flightId, hexAddress, expectedCallsign));

  @override
  Future<bool> claimNotification(
    int flightId,
    FlightNotification kind,
    DateTime deliveredAt,
  ) async {
    if (notificationMarks.contains((flightId, kind))) {
      return false;
    }
    notificationMarks.add((flightId, kind));
    if (kind == FlightNotification.arrivingSoon) {
      arrivingSoonSchedules.remove(flightId);
    }
    return true;
  }

  @override
  Future<void> setArrivingSoonSchedule(int flightId, DateTime? at) async {
    if (at == null) {
      arrivingSoonSchedules.remove(flightId);
    } else {
      arrivingSoonSchedules[flightId] = at;
    }
  }

  @override
  Future<void> setLiveActivityId(int flightId, String? activityId) async {
    if (activityId == null) {
      liveActivityIds.remove(flightId);
    } else {
      liveActivityIds[flightId] = activityId;
    }
  }

  @override
  Future<void> markDueRemindersDelivered(DateTime now) async {
    await pendingReconcile?.future;
    final due = arrivingSoonSchedules.entries
        .where((entry) => !now.isBefore(entry.value))
        .map((entry) => entry.key)
        .toList();
    for (final flightId in due) {
      await claimNotification(
        flightId,
        FlightNotification.arrivingSoon,
        arrivingSoonSchedules[flightId]!,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Serves an empty tile so no widget test ever requests a vector tile.
class StubVectorTileProvider extends VectorTileProvider {
  @override
  int get maximumZoom => 14;

  @override
  int get minimumZoom => 0;

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;

  @override
  Future<Uint8List> provide(TileIdentity tile) async => Uint8List(0);
}

/// Serves a transparent pixel so no widget test ever requests a map tile.
class StubTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(_transparentPixel);
}

final _transparentPixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
  0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
  0x42, 0x60, 0x82,
]);

/// Answers lookups from a script keyed by the queried value and records every
/// request in the order it arrived.
class FakeSourceAdapter implements SourceAdapter {
  final results = <String, LookupResult>{};
  final callsignRequests = <String>[];
  final hexAddressRequests = <String>[];
  final registrationRequests = <String>[];
  Completer<LookupResult>? pendingResult;

  @override
  Future<LookupResult> lookupByCallsign(String callsign) {
    callsignRequests.add(callsign);
    return _resultFor(callsign);
  }

  @override
  Future<LookupResult> lookupByHexAddress(String hexAddress) {
    hexAddressRequests.add(hexAddress);
    return _resultFor(hexAddress);
  }

  @override
  Future<LookupResult> lookupByRegistration(String registration) {
    registrationRequests.add(registration);
    return _resultFor(registration);
  }

  Future<LookupResult> _resultFor(String value) =>
      pendingResult?.future ??
      Future.value(results[value] ?? const LookupSuccess([]));
}

class FakeRouteLookup implements RouteLookup {
  FakeRouteLookup([this.result = const RouteNotFound()]);

  RouteLookupResult result;
  Completer<RouteLookupResult>? pendingResult;
  final requests = <List<String>>[];

  @override
  Future<RouteLookupResult> lookup(List<String> callsignCandidates) {
    requests.add(callsignCandidates);
    return pendingResult?.future ?? Future.value(result);
  }
}
