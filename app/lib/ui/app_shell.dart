import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_icons.dart';
import '../l10n/app_localizations.g.dart';
import 'widgets/chrome/app_tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        tabs: [
          AppTab(icon: AppIcons.map, label: localizations.tabMap),
          AppTab(icon: AppIcons.planeUp, label: localizations.tabList),
          AppTab(icon: AppIcons.ellipsis, label: localizations.tabMore),
        ],
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
