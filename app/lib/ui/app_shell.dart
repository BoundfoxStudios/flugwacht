import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../app_icons.dart';
import '../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const FaIcon(AppIcons.map),
            label: localizations.tabMap,
          ),
          NavigationDestination(
            icon: const FaIcon(AppIcons.list),
            label: localizations.tabList,
          ),
          NavigationDestination(
            icon: const FaIcon(AppIcons.sliders),
            label: localizations.tabMore,
          ),
        ],
      ),
    );
  }
}
