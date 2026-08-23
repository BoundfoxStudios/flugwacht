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
  }

  private func launchUrls(over messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
    let channel = FlutterMethodChannel(name: "flugwacht/launch_url", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      result(call.method == "take" ? LaunchUrl.take() : FlutterMethodNotImplemented)
    }
    return channel
  }

  private var launchUrlChannel: FlutterMethodChannel?
}
