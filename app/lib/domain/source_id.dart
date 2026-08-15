enum SourceId { adsblol, adsbfi, airplanes }

/// The single source the app polls until M10/M12 make it switchable.
const activeSourceId = SourceId.adsblol;

extension SourceIdLabel on SourceId {
  /// The source's own name, never localized.
  String get label => switch (this) {
    SourceId.adsblol => 'adsb.lol',
    SourceId.adsbfi => 'adsb.fi',
    SourceId.airplanes => 'airplanes.live',
  };
}
