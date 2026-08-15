enum SourceId { adsblol, adsbfi, airplanes }

const defaultSourceId = SourceId.adsblol;

/// The sources the app offers; airplanes.live stays out until its gated API
/// access is granted, although the app is otherwise ready to poll it (#57).
const selectableSourceIds = [SourceId.adsblol, SourceId.adsbfi];

extension SourceIdLabel on SourceId {
  /// The source's own name, never localized.
  String get label => switch (this) {
    SourceId.adsblol => 'adsb.lol',
    SourceId.adsbfi => 'adsb.fi',
    SourceId.airplanes => 'airplanes.live',
  };
}
