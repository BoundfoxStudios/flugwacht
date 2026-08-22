/// The url a Live Activity card opens the app with, and the way back. The
/// widget extension gets it handed in its payload, so the shape lives here
/// alone.
const liveActivityUrlScheme = 'flugwacht';

const _flightHost = 'flight';

String liveActivityUrlOf(int flightId) =>
    '$liveActivityUrlScheme://$_flightHost/$flightId';

int? flightIdFromLiveActivityUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed == null ||
      parsed.scheme != liveActivityUrlScheme ||
      parsed.host != _flightHost ||
      parsed.pathSegments.length != 1) {
    return null;
  }
  return int.tryParse(parsed.pathSegments.single);
}
