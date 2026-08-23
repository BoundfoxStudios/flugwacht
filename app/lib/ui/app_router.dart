import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/live_activities/live_activity_service.dart';
import '../data/lookup/airline_directory.dart';
import '../data/lookup/route_lookup.dart';
import '../data/notifications/notification_service.dart';
import '../data/persistence/flight_repository.dart';
import '../data/settings/live_activity_setting.dart';
import '../data/settings/map_style_setting.dart';
import '../data/settings/notification_setting.dart';
import '../data/settings/source_setting.dart';
import '../data/settings/units_setting.dart';
import 'app_shell.dart';
import 'map_selection.dart';
import 'screens/about_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/more_screen.dart';
import 'screens/new_flight_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/map/map_visuals.dart';

GoRouter createAppRouter({
  required FlightRepository flightRepository,
  required AirlineDirectory airlineDirectory,
  required RouteLookup routeLookup,
  required SourceSetting sourceSetting,
  required MapStyleSetting mapStyleSetting,
  required UnitsSetting unitsSetting,
  required NotificationSetting notificationSetting,
  required NotificationService notificationService,
  required LiveActivityService liveActivityService,
  required LiveActivitySetting liveActivitySetting,
  required MapTileSources tileSources,
  required PackageInfo packageInfo,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final mapSelection = MapSelection();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/map',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => MapScreen(
                  flightRepository: flightRepository,
                  selection: mapSelection,
                  sourceSetting: sourceSetting,
                  unitsSetting: unitsSetting,
                  mapStyleSetting: mapStyleSetting,
                  liveActivityService: liveActivityService,
                  tileSources: tileSources,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/list',
                builder: (context, state) => ListScreen(
                  flightRepository: flightRepository,
                  mapSelection: mapSelection,
                  mapStyleSetting: mapStyleSetting,
                  tileSources: tileSources,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => MoreScreen(
                  sourceSetting: sourceSetting,
                  unitsSetting: unitsSetting,
                  packageInfo: packageInfo,
                ),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => NotificationsScreen(
                      notificationSetting: notificationSetting,
                      notificationService: notificationService,
                      liveActivitySetting: liveActivitySetting,
                      liveActivityService: liveActivityService,
                    ),
                  ),
                  GoRoute(
                    path: 'faq',
                    builder: (context, state) => const FaqScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) =>
                        AboutScreen(packageInfo: packageInfo),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/new-flight',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: NewFlightScreen(
            flightRepository: flightRepository,
            airlineDirectory: airlineDirectory,
            routeLookup: routeLookup,
            notificationService: notificationService,
            notificationSetting: notificationSetting,
            liveActivityService: liveActivityService,
            liveActivitySetting: liveActivitySetting,
          ),
        ),
      ),
    ],
  );
  // A notification and a Live Activity card are both about one flight, and
  // the map is where the app shows it.
  for (final flights in [
    notificationService.tappedFlights,
    liveActivityService.tappedFlights,
  ]) {
    flights.listen((flightId) {
      mapSelection.requestedFlightId.value = flightId;
      router.go('/map');
    });
  }
  // The tap that started the app arrives before anything listens; the map is
  // where the app opens anyway.
  mapSelection.requestedFlightId.value = notificationService.launchFlightId;
  // A tapped card that cold-started the app was parked natively and only
  // becomes readable once the engine runs, so it arrives a moment later.
  unawaited(
    liveActivityService.takeLaunchFlight().then((flightId) {
      if (flightId != null) {
        mapSelection.requestedFlightId.value = flightId;
      }
    }),
  );
  return router;
}
