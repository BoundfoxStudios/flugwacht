import Foundation

/// The states the app can put on a card, named as the app names them.
enum FlightPhase: String {
  case planned
  case waiting
  case live
  case noSignal
  case ended
  case missed
}

/// What the app knows about a flight, read from the App Group the plugin
/// writes into. Absent facts arrive as empty strings and zero timestamps
/// rather than missing keys, so a fact that stops applying really disappears
/// instead of leaving its last value behind.
struct FlightCard {
  let url: URL?
  let designator: String
  let note: String?
  let phase: FlightPhase
  let originCode: String?
  let destinationCode: String?
  let departureAt: Date?
  let estimatedArrivalAt: Date?
  let firstAirborneAt: Date?
  let landedAt: Date?

  init(attributes: LiveActivitiesAppAttributes, defaults: UserDefaults?) {
    func text(_ key: String) -> String? {
      let value = defaults?.string(forKey: attributes.prefixedKey(key))
      return value?.isEmpty == false ? value : nil
    }

    func instant(_ key: String) -> Date? {
      guard
        let milliseconds = (defaults?.object(forKey: attributes.prefixedKey(key)) as? NSNumber)?
          .doubleValue,
        milliseconds > 0
      else {
        return nil
      }
      return Date(timeIntervalSince1970: milliseconds / 1000)
    }

    url = text("url").flatMap(URL.init(string:))
    designator = text("designator") ?? ""
    note = text("note")
    phase = text("state").flatMap(FlightPhase.init(rawValue:)) ?? .waiting
    originCode = text("originCode")
    destinationCode = text("destinationCode")
    departureAt = instant("departureAt")
    estimatedArrivalAt = instant("estimatedArrivalAt")
    firstAirborneAt = instant("firstAirborneAt")
    landedAt = instant("landedAt")
  }

  /// A route the card can draw: both ends known.
  var route: (origin: String, destination: String)? {
    guard let originCode, let destinationCode else {
      return nil
    }
    return (originCode, destinationCode)
  }

  /// The span the countdown runs over, built here so it can never end before
  /// it starts — a reversed range traps at render time. A moment that has
  /// already passed leaves no countdown at all, and the card falls back to the
  /// state label the way the spec asks.
  var countdown: (label: CountdownLabel, span: ClosedRange<Date>)? {
    let now = Date.now
    let target: (label: CountdownLabel, at: Date)? = switch phase {
    case .live, .noSignal: estimatedArrivalAt.map { (.landing, $0) }
    case .planned, .waiting: departureAt.map { (.departure, $0) }
    case .ended, .missed: nil
    }
    guard let target, target.at > now else {
      return nil
    }
    return (target.label, now...target.at)
  }

  /// The span the progress bar fills over, anchored on the moment the flight
  /// left the ground; the scheduled departure stands in until it did.
  var progress: ClosedRange<Date>? {
    guard let estimatedArrivalAt, let start = firstAirborneAt ?? departureAt,
      start < estimatedArrivalAt
    else {
      return nil
    }
    return start...estimatedArrivalAt
  }

  /// When the flight touched down, once it has.
  var landing: Date? {
    phase == .ended ? landedAt : nil
  }

  /// The arrival the card still counts towards; a flight that is down has one
  /// in the past and shows its landing instead.
  var arrival: Date? {
    phase == .ended ? nil : estimatedArrivalAt
  }

  /// The estimate ran out without the app seeing the aircraft on the ground.
  /// It can only see that while it runs, so the card says what it honestly
  /// knows rather than counting to a moment that has passed.
  var hasProbablyLanded: Bool {
    guard phase == .live || phase == .noSignal, let estimatedArrivalAt else {
      return false
    }
    return estimatedArrivalAt <= Date.now
  }

  /// Whether the arrival time is a guess the app could not confirm.
  var isArrivalUncertain: Bool {
    phase == .noSignal
  }
}

enum CountdownLabel {
  case departure
  case landing
}
