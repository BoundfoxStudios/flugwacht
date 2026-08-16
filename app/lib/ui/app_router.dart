import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/airline_directory.dart';
import '../data/flight_repository.dart';
import '../data/map_style_setting.dart';
import '../data/notification_service.dart';
import '../data/notification_setting.dart';
import '../data/route_lookup.dart';
import '../data/source_setting.dart';
import '../data/units_setting.dart';
import 'app_shell.dart';
import 'map_selection.dart';
import 'screens/list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/more_screen.dart';
import 'screens/new_flight_screen.dart';
import 'widgets/map_visuals.dart';

GoRouter createAppRouter({
  required FlightRepository flightRepository,
  required AirlineDirectory airlineDirectory,
  required RouteLookup routeLookup,
  required SourceSetting sourceSetting,
  required MapStyleSetting mapStyleSetting,
  required UnitsSetting unitsSetting,
  required NotificationSetting notificationSetting,
  required NotificationService notificationService,
  required MapTileSources tileSources,
  required PackageInfo packageInfo,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final mapSelection = MapSelection();
  return GoRouter(
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
                  notificationSetting: notificationSetting,
                  notificationService: notificationService,
                  packageInfo: packageInfo,
                ),
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
          ),
        ),
      ),
    ],
  );
}
