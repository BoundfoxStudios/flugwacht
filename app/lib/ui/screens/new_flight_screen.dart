import 'package:flutter/material.dart';

class NewFlightScreen extends StatelessWidget {
  const NewFlightScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New flight')),
    body: const Center(child: Text('New flight')),
  );
}
