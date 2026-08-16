enum SourceId { adsblol, adsbfi, airplanes }

const defaultSourceId = SourceId.adsblol;

/// The sources the app offers; airplanes.live stays out until its gated API
/// access is granted, although the app is otherwise ready to poll it (#57).
const selectableSourceIds = [SourceId.adsblol, SourceId.adsbfi];

/// The source a switch lands on, wrapping around and leaving whatever is not
/// selectable behind.
SourceId nextSelectableSourceId(SourceId current) {
  final index = selectableSourceIds.indexOf(current);
  return selectableSourceIds[(index + 1) % selectableSourceIds.length];
}

extension SourceIdLabel on SourceId {
  /// The source's own name, never localized.
  String get label => switch (this) {
    SourceId.adsblol => 'adsb.lol',
    SourceId.adsbfi => 'adsb.fi',
    SourceId.airplanes => 'airplanes.live',
  };

  /// The name a credit carries, with the license the source puts on its data.
  String get licenseLabel => switch (this) {
    SourceId.adsblol => '$label (ODbL)',
    SourceId.adsbfi || SourceId.airplanes => label,
  };
}
