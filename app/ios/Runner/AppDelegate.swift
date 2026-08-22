import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LaunchUrl")
    else {
      return
    }
    launchUrlChannel = FlutterMethodChannel(
      name: "flugwacht/launch_url",
      binaryMessenger: registrar.messenger()
    )
    launchUrlChannel?.setMethodCallHandler { call, result in
      result(call.method == "take" ? LaunchUrl.take() : FlutterMethodNotImplemented)
    }
  }

  private var launchUrlChannel: FlutterMethodChannel?
}
