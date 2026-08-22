import SwiftUI
import WidgetKit

/// The Lock Screen card: who is flying, where they are on the way, and when
/// they land. Every running number is driven by the system clock, so the card
/// stays right while the app is closed.
struct FlightCardView: View {
  let card: FlightCard
  let isStale: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      titleRow
      if let route = card.route {
        RouteProgressBar(
          origin: route.origin,
          destination: route.destination,
          span: card.progress,
          isComplete: card.phase == .ended
        )
      }
      bottomRow
    }
    .padding(16)
    .opacity(isStale ? 0.55 : 1)
  }

  private var titleRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Image(systemName: "airplane")
        .font(.system(size: 12))
        .foregroundStyle(FlugwachtColor.accent)
      Text(card.note.map { "\(card.designator) · \($0)" } ?? card.designator)
        .font(FlugwachtFont.emphasis(15))
        .foregroundStyle(FlugwachtColor.primary)
        .lineLimit(1)
      Spacer(minLength: 8)
      Text(phaseLabel)
        .font(FlugwachtFont.numerals(13))
        .tracking(0.8)
        .foregroundStyle(card.phase == .live ? FlugwachtColor.accent : FlugwachtColor.secondary)
        .lineLimit(1)
    }
  }

  @ViewBuilder private var bottomRow: some View {
    HStack(alignment: .firstTextBaseline) {
      countdown
      Spacer(minLength: 8)
      arrival
    }
  }

  @ViewBuilder private var countdown: some View {
    if card.phase == .ended, let landedAt = card.landedAt {
      HStack(spacing: 6) {
        Text("Landed")
          .font(FlugwachtFont.text(13))
          .foregroundStyle(FlugwachtColor.secondary)
        Text(landedAt, style: .time)
          .font(FlugwachtFont.numerals(20))
          .foregroundStyle(FlugwachtColor.primary)
      }
    } else if let countdown = card.countdown {
      HStack(spacing: 6) {
        Text(countdown.label == .departure ? "Departure in" : "Landing in")
          .font(FlugwachtFont.text(13))
          .foregroundStyle(FlugwachtColor.secondary)
        Text(timerInterval: Date.now...countdown.target, countsDown: true)
          .font(FlugwachtFont.numerals(20))
          .foregroundStyle(FlugwachtColor.primary)
          .monospacedDigit()
          .frame(maxWidth: 74, alignment: .leading)
      }
    } else if isStale {
      Text("Data outdated")
        .font(FlugwachtFont.text(13))
        .foregroundStyle(FlugwachtColor.secondary)
    }
  }

  @ViewBuilder private var arrival: some View {
    if card.phase != .ended, let arrivesAt = card.estimatedArrivalAt {
      HStack(spacing: 2) {
        if card.isArrivalUncertain || isStale {
          Text(verbatim: "~")
            .font(FlugwachtFont.numerals(15))
            .foregroundStyle(FlugwachtColor.secondary)
        }
        Text("ETA \(arrivesAt, style: .time)")
          .font(FlugwachtFont.text(13))
          .foregroundStyle(FlugwachtColor.secondary)
      }
      .lineLimit(1)
    }
  }

  private var phaseLabel: LocalizedStringKey {
    switch card.phase {
    case .planned: "PLANNED"
    case .waiting: "WAITING"
    case .live: "LIVE"
    case .noSignal: "NO SIGNAL"
    case .ended: "ENDED"
    case .missed: "MISSED"
    }
  }
}

/// Origin and destination with the aircraft between them. The fill runs off
/// the system clock, so it keeps moving without an update from the app.
struct RouteProgressBar: View {
  let origin: String
  let destination: String
  let span: ClosedRange<Date>?
  let isComplete: Bool

  var body: some View {
    HStack(spacing: 8) {
      Text(origin)
        .font(FlugwachtFont.numerals(15))
        .foregroundStyle(FlugwachtColor.secondary)
      bar
      Text(destination)
        .font(FlugwachtFont.numerals(15))
        .foregroundStyle(FlugwachtColor.secondary)
    }
  }

  @ViewBuilder private var bar: some View {
    if let span, !isComplete {
      ProgressView(timerInterval: span, countsDown: false) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .progressViewStyle(.linear)
      .tint(FlugwachtColor.accent)
    } else {
      ProgressView(value: isComplete ? 1 : 0)
        .progressViewStyle(.linear)
        .tint(FlugwachtColor.accent)
    }
  }
}
