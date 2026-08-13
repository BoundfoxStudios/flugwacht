import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app_icons.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const Center(child: Text('List')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/new-flight'),
      child: const FaIcon(AppIcons.plus),
    ),
  );
}
