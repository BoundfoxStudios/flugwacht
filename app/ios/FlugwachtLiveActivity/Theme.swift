import SwiftUI
import UIKit

/// The app's tokens, as far as a Lock Screen card uses them.
enum FlugwachtColor {
  static let accent = Color(red: 1, green: 0.757, blue: 0.027)
  static let primary = adaptive(light: 0.09, dark: 0.98)
  static let secondary = adaptive(light: 0.451, dark: 0.639)
  static let track = adaptive(light: 0.831, dark: 0.251)

  private static func adaptive(light: CGFloat, dark: CGFloat) -> Color {
    Color(
      UIColor { traits in
        UIColor(white: traits.userInterfaceStyle == .dark ? dark : light, alpha: 1)
      }
    )
  }
}

/// Bebas Neue carries the numerals, Barlow the words — the same split the app
/// uses. Both ship inside this target; SwiftUI falls back to the system face
/// if a name ever stops matching.
enum FlugwachtFont {
  static func numerals(_ size: CGFloat) -> Font {
    .custom("BebasNeue-Regular", size: size)
  }

  static func text(_ size: CGFloat) -> Font {
    .custom("Barlow-Regular", size: size)
  }

  static func emphasis(_ size: CGFloat) -> Font {
    .custom("Barlow-SemiBold", size: size)
  }
}
