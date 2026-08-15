import 'package:signals/signals.dart';

/// The flight the map frames, shared by the map and the list so a tap on a
/// hero cell lands on the same selection a marker tap makes.
class MapSelection {
  final flightId = signal<int?>(null);

  void dispose() => flightId.dispose();
}
