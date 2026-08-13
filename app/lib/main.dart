import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/app_router.dart';

void main() {
  runApp(FlugwachtApp(router: createAppRouter()));
}

class FlugwachtApp extends StatelessWidget {
  const FlugwachtApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Flugwacht',
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    routerConfig: router,
  );
}
