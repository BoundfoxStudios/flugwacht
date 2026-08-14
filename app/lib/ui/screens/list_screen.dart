import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app_icons.dart';
import '../../l10n/app_localizations.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(
        AppLocalizations.of(context).tabList,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/new-flight'),
      child: const FaIcon(AppIcons.plus),
    ),
  );
}
