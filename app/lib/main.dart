import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'data/adapters/readsb_source_adapter.dart';
import 'data/font_licenses.dart';
import 'data/live_activities/flight_live_activities.dart';
import 'data/live_activities/live_activity_service.dart';
import 'data/live_activities/notification_live_activity_service.dart';
import 'data/lookup/airline_directory.dart';
import 'data/lookup/route_lookup.dart';
import 'data/notifications/flight_notifier.dart';
import 'data/notifications/notification_service.dart';
import 'data/persistence/database.dart';
import 'data/persistence/flight_repository.dart';
import 'data/polling_engine.dart';
import 'data/settings/live_activity_setting.dart';
import 'data/settings/map_style_setting.dart';
import 'data/settings/notification_setting.dart';
import 'data/settings/source_setting.dart';
import 'data/settings/units_setting.dart';
import 'data/vector_tile_source.dart';
import 'domain/airport_timezone.dart';
import 'domain/source_id.dart';
import 'l10n/app_localization_delegates.dart';
import 'l10n/app_localizations.g.dart';
import 'ui/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/flight/flight_labels.dart';
import 'ui/widgets/flight/live_activity_labels.dart';
import 'ui/widgets/map/map_visuals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  initializeAirportTimezones();
  final client = http.Client();
  final flightRepository = FlightRepository(AppDatabase());
  final airlineDirectory = await AirlineDirectory.loadFromAssets();
  final sourceSetting = await SourceSetting.load();
  final mapStyleSetting = await MapStyleSetting.load();
  final unitsSetting = await UnitsSetting.load();
  final notificationSetting = await NotificationSetting.load();
  final liveActivitySetting = await LiveActivitySetting.load();
  final packageInfo = await PackageInfo.fromPlatform();
  final localizations = await AppLocalizations.delegate.load(
    basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  // The card's copy formats times outside any widget, and nothing else loads
  // the locale's date symbols before the first frame is built.
  await initializeDateFormatting(localizations.localeName);
  final notificationService = await LocalNotificationService.start(
    channelName: localizations.notificationChannelName,
    channelDescription: localizations.notificationChannelDescription,
  );
  final liveActivityService = await _startLiveActivities(
    localizations,
    notificationService,
  );
  // Not awaited: the map draws its ground as soon as the planet run is known,
  // and starts without tiles rather than without a first frame.
  final vectorTileSource = VectorTileSource(client: client);
  unawaited(vectorTileSource.load());
  PollingEngine(
    repository: flightRepository,
    adapters: {
      for (final sourceId in SourceId.values)
        sourceId: ReadsbSourceAdapter(sourceId: sourceId, client: client),
    },
    activeSourceId: () => sourceSetting.activeId.value,
    airlineDirectory: airlineDirectory,
    notifier: FlightNotifier(
      repository: flightRepository,
      service: notificationService,
      setting: notificationSetting,
      copy: (kind, flight) =>
          flightNotificationText(localizations, kind, flight),
    ),
    liveActivities: FlightLiveActivities(
      repository: flightRepository,
      service: liveActivityService,
      notifications: notificationService,
      setting: liveActivitySetting,
      copy: (flight) => flightLiveActivityReminderText(localizations, flight),
    ),
  ).start();
  runApp(
    FlugwachtApp(
      router: createAppRouter(
        flightRepository: flightRepository,
        airlineDirectory: airlineDirectory,
        routeLookup: RouteLookup(client: client),
        sourceSetting: sourceSetting,
        mapStyleSetting: mapStyleSetting,
        unitsSetting: unitsSetting,
        notificationSetting: notificationSetting,
        notificationService: notificationService,
        liveActivityService: liveActivityService,
        liveActivitySetting: liveActivitySetting,
        tileSources: MapTileSources(
          userAgentPackageName: packageInfo.packageName,
          vectorTileProviders: vectorTileSource.providers,
        ),
        packageInfo: packageInfo,
      ),
    ),
  );
}

/// The card is an iOS Live Activity and an Android notification, so which
/// service runs is a platform decision. Android's rides on the notification
/// stack, and a device that could not set that up gets no card either.
Future<LiveActivityService> _startLiveActivities(
  AppLocalizations localizations,
  NotificationService notifications,
) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return PluginLiveActivityService.start();
  }
  if (notifications.permission.value == NotificationPermission.unavailable) {
    return Future.value(UnavailableLiveActivityService());
  }
  return NotificationLiveActivityService.start(
    copy: (card) => flightCardText(localizations, card),
    channelName: localizations.lockScreenChannelName,
    channelDescription: localizations.lockScreenChannelDescription,
  );
}

class FlugwachtApp extends StatelessWidget {
  const FlugwachtApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: appLocalizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    routerConfig: router,
  );
}
