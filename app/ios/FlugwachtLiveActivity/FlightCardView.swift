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
      // A flight without a departure time, a route or an estimate has nothing
      // to say down here, and an empty row would only add a gap.
      if hasBottomRow {
        bottomRow
      }
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

  private var hasBottomRow: Bool {
    isStale || card.countdown != nil || card.landing != nil
        || card.arrival != nil || card.hasProbablyLanded
  }

  @ViewBuilder private var bottomRow: some View {
    HStack(alignment: .firstTextBaseline) {
      countdown
      Spacer(minLength: 8)
      arrival
    }
  }

  @ViewBuilder private var countdown: some View {
    if let landedAt = card.landing {
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
        Text(timerInterval: countdown.span, countsDown: true)
          .font(FlugwachtFont.numerals(20))
          .foregroundStyle(FlugwachtColor.primary)
          .monospacedDigit()
          .frame(maxWidth: 74, alignment: .leading)
      }
    } else if card.hasProbablyLanded {
      Text("Probably landed · open the app")
        .font(FlugwachtFont.text(13))
        .foregroundStyle(FlugwachtColor.secondary)
        .lineLimit(1)
    } else {
      staleHint
    }
  }

  /// The card only says its data is old where nothing else occupies the line;
  /// next to a running countdown the dimmed look and the ~ before the ETA
  /// already carry it.
  @ViewBuilder private var staleHint: some View {
    if isStale {
      Text("Data outdated")
        .font(FlugwachtFont.text(13))
        .foregroundStyle(FlugwachtColor.secondary)
    }
  }

  @ViewBuilder private var arrival: some View {
    // An estimate that has run out says nothing useful next to the hint that
    // the flight probably arrived.
    if let arrivesAt = card.arrival, !card.hasProbablyLanded {
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
