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
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QichengClipboard") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "qicheng/clipboard",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let image = UIPasteboard.general.image,
         let data = image.jpegData(compressionQuality: 0.88) {
        result(FlutterStandardTypedData(bytes: data))
      } else {
        result(nil)
      }
    }
  }
}
