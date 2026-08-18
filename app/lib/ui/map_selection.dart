import 'package:signals/signals.dart';

/// The flight the map frames, shared by the map and the list so a tap on a
/// hero cell lands on the same selection a marker tap makes.
class MapSelection {
  final flightId = signal<int?>(null);

  /// A flight the app was asked to frame before the map knows it: a tapped
  /// notification names its flight while the flights are still loading.
  final requestedFlightId = signal<int?>(null);

  void dispose() {
    flightId.dispose();
    requestedFlightId.dispose();
  }
}
