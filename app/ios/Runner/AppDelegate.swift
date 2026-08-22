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
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Flugwacht")
    else {
      return
    }
    launchUrlChannel = launchUrls(over: registrar.messenger())
    staleDateChannel = staleDates(over: registrar.messenger())
  }

  private func launchUrls(over messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(name: "flugwacht/launch_url", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      result(call.method == "take" ? LaunchUrl.take() : FlutterMethodNotImplemented)
    }
    return channel
  }

  private func staleDates(over messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(
      name: "flugwacht/live_activity_stale",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "renew",
        let arguments = call.arguments as? [String: Any],
        let url = arguments["url"] as? String,
        let milliseconds = arguments["atMilliseconds"] as? Int
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      LiveActivityStaleDate.renew(
        cardAt: url,
        until: Date(timeIntervalSince1970: Double(milliseconds) / 1000)
      )
      result(nil)
    }
    return channel
  }

  private var launchUrlChannel: FlutterMethodChannel?
  private var staleDateChannel: FlutterMethodChannel?
}
