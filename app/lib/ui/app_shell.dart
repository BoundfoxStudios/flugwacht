import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'widgets/app_tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        labels: [
          localizations.tabMap,
          localizations.tabList,
          localizations.tabMore,
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
