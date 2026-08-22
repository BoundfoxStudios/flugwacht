import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('without live activities', () {
    late LiveActivityService service;

    setUp(() => service = UnavailableLiveActivityService());

    test('reports the activities as unsupported', () {
      expect(service.availability.value, LiveActivityAvailability.unsupported);
    });

    test('finds nothing to pick up from the system settings', () async {
      await service.refreshAvailability();
      expect(service.availability.value, LiveActivityAvailability.unsupported);
    });

    test('starts nothing', () async {
      await expectLater(
        service.put('activity-1', data: const {}, staleIn: Duration.zero),
        completes,
      );
    });

    test('ends nothing', () async {
      await expectLater(service.end('activity-1'), completes);
    });

    test('knows nothing about an activity', () async {
      expect(
        await service.presenceOf('activity-1'),
        LiveActivityPresence.unknown,
      );
    });

    test('hands up no tapped flight', () async {
      expect(await service.tappedFlights.isEmpty, isTrue);
    });
  });
}
