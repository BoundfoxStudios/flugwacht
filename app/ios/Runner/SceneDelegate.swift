import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    LaunchUrl.remember(connectionOptions.urlContexts.first?.url)
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}

/// The url the app was started with.
///
/// A tapped Live Activity card reaches a running app through the plugin's own
/// scene callback, but a cold start delivers its url before Dart is listening
/// — and before the plugin exists at all. The scene delegate parks it here and
/// Dart picks it up once it is ready.
enum LaunchUrl {
  private static let lock = NSLock()
  private static var pending: URL?

  static func remember(_ url: URL?) {
    guard let url else {
      return
    }
    lock.lock()
    defer { lock.unlock() }
    pending = url
  }

  /// Hands the url over exactly once; a second reader would act on a tap that
  /// has already been answered.
  static func take() -> String? {
    lock.lock()
    defer { lock.unlock() }
    let url = pending
    pending = nil
    return url?.absoluteString
  }
}
