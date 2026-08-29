import ActivityKit
import Foundation

/// The contract of the `live_activities` plugin: it requests every activity as
/// `Activity<LiveActivitiesAppAttributes>`, so the name and shape have to match
/// its own declaration exactly. The payload itself does not travel in here – it
/// goes through the App Group, keyed by this id.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {
    var appGroupId: String?

    init(appGroupId: String? = nil) {
      self.appGroupId = appGroupId
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
      appGroupId = try container.decodeIfPresent(
        String.self,
        forKey: DynamicCodingKeys("appGroupId")
      )
    }
  }

  var id: UUID

  init(id: UUID = UUID()) {
    self.id = id
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
    id = try container.decodeIfPresent(UUID.self, forKey: DynamicCodingKeys("id")) ?? UUID()
  }

  struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ stringValue: String) {
      self.stringValue = stringValue
      intValue = nil
    }

    init?(stringValue: String) {
      self.init(stringValue)
    }

    init?(intValue: Int) {
      nil
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    "\(id)_\(key)"
  }
}
