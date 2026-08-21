import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity of one flight. Everything it shows comes out of the App
/// Group the app writes into; the activity itself only carries the id that
/// keys it.
struct FlightLiveActivity: Widget {
  private static let appGroupId = "group.com.boundfoxstudios.apps.flugwacht"

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let card = card(for: context)
      FlightCardView(card: card, isStale: context.isStale)
        .widgetURL(card.url)
        .activityBackgroundTint(nil)
    } dynamicIsland: { context in
      let card = card(for: context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.bottom) {
          FlightCardView(card: card, isStale: context.isStale)
        }
      } compactLeading: {
        planeIcon
      } compactTrailing: {
        compactCountdown(for: card)
      } minimal: {
        planeIcon
      }
      .widgetURL(card.url)
      .keylineTint(FlugwachtColor.accent)
    }
  }

  private var planeIcon: some View {
    Image(systemName: "airplane")
      .foregroundStyle(FlugwachtColor.accent)
  }

  @ViewBuilder private func compactCountdown(for card: FlightCard) -> some View {
    if let countdown = card.countdown {
      Text(timerInterval: Date.now...countdown.target, countsDown: true)
        .font(FlugwachtFont.numerals(15))
        .foregroundStyle(FlugwachtColor.accent)
        .monospacedDigit()
        .frame(maxWidth: 44)
    }
  }

  private func card(for context: ActivityViewContext<LiveActivitiesAppAttributes>) -> FlightCard {
    FlightCard(
      attributes: context.attributes,
      defaults: UserDefaults(suiteName: context.state.appGroupId ?? Self.appGroupId)
    )
  }
}

private let previewAppGroupId = "group.com.boundfoxstudios.apps.flugwacht"

private func millisecondsFromNow(_ seconds: TimeInterval) -> Int {
  Int(Date.now.addingTimeInterval(seconds).timeIntervalSince1970 * 1000)
}

/// Puts a card's facts where the widget reads them, so a preview exercises the
/// same App Group path a real activity takes.
private func seeded(_ values: [String: Any], id: String) -> LiveActivitiesAppAttributes {
  let attributes = LiveActivitiesAppAttributes(id: UUID(uuidString: id) ?? UUID())
  let defaults = UserDefaults(suiteName: previewAppGroupId)
  for (key, value) in values {
    defaults?.set(value, forKey: attributes.prefixedKey(key))
  }
  return attributes
}

private func previewFlight(
  state: String,
  note: String = "Papa",
  origin: String = "FRA",
  destination: String = "SFO",
  departureIn: TimeInterval? = nil,
  arrivesIn: TimeInterval? = nil,
  airborneSince: TimeInterval? = nil,
  landedAgo: TimeInterval? = nil
) -> [String: Any] {
  [
    "url": "flugwacht://flight/1",
    "designator": "LH 454",
    "note": note,
    "state": state,
    "originCode": origin,
    "destinationCode": destination,
    "departureAt": departureIn.map(millisecondsFromNow) ?? 0,
    "estimatedArrivalAt": arrivesIn.map(millisecondsFromNow) ?? 0,
    "firstAirborneAt": airborneSince.map { millisecondsFromNow(-$0) } ?? 0,
    "landedAt": landedAgo.map { millisecondsFromNow(-$0) } ?? 0,
  ]
}

extension LiveActivitiesAppAttributes {
  fileprivate static var inTheAir: LiveActivitiesAppAttributes {
    seeded(
      previewFlight(state: "live", arrivesIn: 9660, airborneSince: 3000),
      id: "A0000000-0000-4000-8000-000000000001"
    )
  }

  fileprivate static var withoutSignal: LiveActivitiesAppAttributes {
    seeded(
      previewFlight(state: "noSignal", arrivesIn: 5400, airborneSince: 7200),
      id: "A0000000-0000-4000-8000-000000000002"
    )
  }

  fileprivate static var beforeDeparture: LiveActivitiesAppAttributes {
    seeded(
      previewFlight(state: "planned", departureIn: 7200),
      id: "A0000000-0000-4000-8000-000000000003"
    )
  }

  fileprivate static var landed: LiveActivitiesAppAttributes {
    seeded(
      previewFlight(state: "ended", landedAgo: 300),
      id: "A0000000-0000-4000-8000-000000000004"
    )
  }

  fileprivate static var withoutRoute: LiveActivitiesAppAttributes {
    seeded(
      previewFlight(state: "waiting", note: "", origin: "", destination: ""),
      id: "A0000000-0000-4000-8000-000000000005"
    )
  }
}

extension LiveActivitiesAppAttributes.ContentState {
  fileprivate static var shared: LiveActivitiesAppAttributes.ContentState {
    LiveActivitiesAppAttributes.ContentState(appGroupId: previewAppGroupId)
  }
}

#Preview("live", as: .content, using: LiveActivitiesAppAttributes.inTheAir) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}

#Preview("no signal", as: .content, using: LiveActivitiesAppAttributes.withoutSignal) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}

#Preview("before departure", as: .content, using: LiveActivitiesAppAttributes.beforeDeparture) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}

#Preview("landed", as: .content, using: LiveActivitiesAppAttributes.landed) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}

#Preview("without a route", as: .content, using: LiveActivitiesAppAttributes.withoutRoute) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}

#Preview("dynamic island", as: .dynamicIsland(.expanded), using: LiveActivitiesAppAttributes.inTheAir) {
  FlightLiveActivity()
} contentStates: {
  LiveActivitiesAppAttributes.ContentState.shared
}
