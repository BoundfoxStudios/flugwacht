import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/airline_directory.dart';
import '../data/flight_repository.dart';
import '../data/route_lookup.dart';
import '../data/source_setting.dart';
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
  required MapTileSources tileSources,
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
                  tileSources: tileSources,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
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
          ),
        ),
      ),
    ],
  );
}
