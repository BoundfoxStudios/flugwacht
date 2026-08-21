import 'package:flugwacht/data/live_activities/live_activity_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names the flight a card opens', () {
    expect(liveActivityUrlOf(12), 'flugwacht://flight/12');
  });

  test('reads the flight out of a tapped card', () {
    expect(flightIdFromLiveActivityUrl('flugwacht://flight/12'), 12);
  });

  test('reads no flight out of a url of another scheme', () {
    expect(flightIdFromLiveActivityUrl('https://flight/12'), isNull);
  });

  test('reads no flight out of a url that names none', () {
    expect(flightIdFromLiveActivityUrl('flugwacht://flight'), isNull);
  });

  test('reads no flight out of a url that names something else', () {
    expect(flightIdFromLiveActivityUrl('flugwacht://settings/12'), isNull);
  });

  test('reads no flight out of a url whose flight is not a number', () {
    expect(flightIdFromLiveActivityUrl('flugwacht://flight/LH433'), isNull);
  });
}
