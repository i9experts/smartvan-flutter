import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Key comes from ios/Flutter/Secrets.xcconfig (gitignored) via the
    // GMSApiKey entry in Info.plist.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !key.isEmpty {
      GMSServices.provideAPIKey(key)
    } else {
      NSLog("GMSApiKey missing — set MAPS_API_KEY in ios/Flutter/Secrets.xcconfig")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
