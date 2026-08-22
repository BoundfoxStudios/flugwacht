import ActivityKit
import Foundation

/// The moment iOS stops trusting a card, renewed whenever the app puts fresh
/// data on one.
///
/// The `live_activities` plugin hands that moment to the system when it
/// creates an activity and never again, so an updated card would keep counting
/// towards the moment its first put named. The window matters more than that:
/// it is the only clock the app can leave behind. iOS renders the card once
/// more when it runs out, and that is the single chance a card has to stop
/// counting towards an estimate that passed while the app was closed.
enum LiveActivityStaleDate {
  /// Finds the card by the url it carries: the plugin hashes the app's own
  /// activity id into the activity and keeps that hash to itself, so the data
  /// in the App Group is the one place the two identifiers meet.
  static func renew(cardAt url: String, until staleDate: Date) {
    Task {
      for activity in Activity<LiveActivitiesAppAttributes>.activities {
        let state = activity.content.state
        let defaults = state.appGroupId.flatMap(UserDefaults.init(suiteName:))
        if defaults?.string(forKey: "\(activity.attributes.id)_url") == url {
          await activity.update(ActivityContent(state: state, staleDate: staleDate))
        }
      }
    }
  }
}

/// The plugin's contract, a second time: it declares the type privately, and
/// ActivityKit matches activities by the name of their attributes — so this
/// copy reaches the very activities the plugin requested. The widget extension
/// carries a third one for its own bundle.
struct LiveActivitiesAppAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var appGroupId: String?
  }

  var id: UUID
}
