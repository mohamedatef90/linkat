import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appGroupId = "group.com.example.linkat"
  private let pendingLinksKey = "PendingLinks"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup method channel for pending links
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.example.linkat/pending_links",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getPendingLinks":
        result(self?.getPendingLinks())
      case "clearPendingLinks":
        self?.clearPendingLinks()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getPendingLinks() -> String? {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("Runner: Could not access UserDefaults with app group: \(appGroupId)")
      return nil
    }

    // Try to read as string first (how we save it)
    if let jsonString = userDefaults.string(forKey: pendingLinksKey) {
      print("Runner: Found pending links - \(jsonString)")
      return jsonString
    }

    // Fallback: try to read as data
    if let data = userDefaults.data(forKey: pendingLinksKey),
       let jsonString = String(data: data, encoding: .utf8) {
      print("Runner: Found pending links (as data) - \(jsonString)")
      return jsonString
    }

    print("Runner: No pending links found")
    return nil
  }

  private func clearPendingLinks() {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    userDefaults.removeObject(forKey: pendingLinksKey)
    userDefaults.synchronize()
    print("Runner: Cleared pending links")
  }

  // Handle URL scheme when app is launched from share extension
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Let the plugin handle the URL
    return super.application(app, open: url, options: options)
  }
}
