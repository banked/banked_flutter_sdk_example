import UIKit
import Flutter
import Banked

private let CHANNEL = "com.example.banked_flutter_sdk_example/banked_sdk"
private let BANKED_API_KEY = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let bankedSDKChannel = FlutterMethodChannel(name: CHANNEL,
                                              binaryMessenger: controller.binaryMessenger)
    bankedSDKChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      // Note: this method is invoked on the UI thread.
        guard call.method == "startSdk" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        guard let arguments = call.arguments as? [String : Any] else {
            result(FlutterError(code: "NO_ARGUMENTS", message: "Can't extract flutter arguments", details: nil))
            return
        }
        
        guard let paymentId = arguments["payment id"] as? String else {
            result(FlutterError(code: "NO_PAYMENT_ID", message: "PaymentId can't be nil", details: nil))
            return
        }
        guard let continueUrl = arguments["continue url"] as? String else {
            result(FlutterError(code: "NO_CONTINUE_URL", message: "Continue url can't be nil", details: nil))
            return
        }

        self?.presentBankedCheckout(result: result, paymetId: paymentId, continueURL: continueUrl)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func presentBankedCheckout(result: FlutterResult, paymetId: String, continueURL: String) {
        
        guard let viewController = self.window.rootViewController else {
            result(FlutterError(code: "NO_VIEWCONTROLLER", message: "ViewController can't be nil", details: nil))
            return
        }
                
        BankedCheckout.shared.setUp(BANKED_API_KEY)
        
        BankedCheckout.shared.presentCheckout(viewController, paymentId: paymetId, action: .pay, continueURL: continueURL) { (response) in
            switch response {
            case .success:
                // Handle Success
                print("success")
            case .failure(let error):
                // Handle Error
                print("error \(error)")
            }
        }
    }
}
