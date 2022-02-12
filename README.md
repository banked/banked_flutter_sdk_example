# Banked Flutter SDK Example

Here is an example project on how to integrate the existing native Android and iOS SDKs into a Flutter app.

## Android Integration

1. Add the latest gradle dependency into the Android app module build file

```
implementation "com.banked:checkout:2.0.1-beta12"
```

2. Add an intent filter into the application manin activity so that the SDK can receive events from the banking providers
```
</intent-filter>
    <intent-filter>
    <action android:name="android.intent.action.VIEW" />

    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <data
        android:host="<host>"
        android:scheme="<scheme>" />
    </intent-filter>
```

3. Create a ```MethodChannel``` in the dart file to send and receive messages to and from the Android activity.
```
 static const methodChannel = const MethodChannel('com.example.banked_flutter_sdk_example/banked_sdk');

  _MyHomePageState() {
    methodChannel.setMethodCallHandler((call) => _processSdkCallback(call));
  }
```

4. Create a function to process incoming messages from the activity.
```
Future<dynamic> _processSdkCallback(MethodCall call) async {
    print("Call - " + call.method);

    String newStatus = "Unknown";

    if (call.method == "BankedSdkPaymentSuccess") {
      newStatus = "Payment Success";
    } else if (call.method == "BankedSdkPaymentSuccess") {
      newStatus = "Payment Failed";
    } else if (call.method == "BankedSdkPaymentAborted") {
      newStatus = "Payment Aborted";
    }

    setState(() {
      _sdkStatus = newStatus;
    });
  }
```

5. Start the SDK in the dart file as follows.
```
Future<void> _startBankedSdk() async {
    String sdkStatus;
    try {
      final Map params = <String, dynamic>{
        'payment id': "Add your payment ID here",
        'continue url': "Add your continue URL here",
      };

      await methodChannel.invokeMethod('startSdk', params);
      sdkStatus = "Waiting for SDK result";
    } on PlatformException catch (e) {
      sdkStatus = "Failed to get start Banked SDK: '${e.message}'.";
    }
    setState(() {
      _sdkStatus = sdkStatus;
    });
  }
```

6. Add the following code to your activity to setup the Banked SDK to initialise, send events to the common dart code and receive events from the dart code and SDK.
```
private const val CHANNEL = "com.example.banked_flutter_sdk_example/banked_sdk"
private const val BANKED_API_KEY = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

class MainActivity : FlutterFragmentActivity(), OnPaymentSessionListener {

    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Banked.setOnPaymentSessionListener(this)
        Banked.setApiKey(BANKED_API_KEY)
    }

    override fun onDestroy() {
        Banked.setOnPaymentSessionListener(null)
        super.onDestroy()
    }

    override fun onStart() {
        super.onStart()
        Banked.onStart(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (methodChannel == null) {
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )

            methodChannel?.setMethodCallHandler { call, result ->
                if (call.method == "startSdk") {
                    val arguments = call.arguments as Map<String, Any>
                    val paymentId = arguments["payment id"]?.toString() ?: "XXXXXXXX"
                    val continueUrl = arguments["continue url"]?.toString() ?: "XXXXXXXX"

                    Banked.startPayment(
                        this,
                        paymentId,
                        continueUrl
                    )
                    result.success("SDK Started")
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onPaymentFailed(paymentResult: PaymentResult) {
        methodChannel?.invokeMethod("BankedSdkPaymentFailed", toParameterMap(paymentResult))
    }

    override fun onPaymentSuccess(paymentResult: PaymentResult) {
        methodChannel?.invokeMethod("BankedSdkPaymentSuccess", toParameterMap(paymentResult))
    }
    
    override fun onPaymentAborted() {
        methodChannel?.invokeMethod("BankedSdkPaymentAborted", mapOf<String, String>())
    }

    private fun toParameterMap(paymentResult: PaymentResult): Map<String, String> {
        return mapOf(
            "paymentId" to paymentResult.paymentId,
            "amountFormatted" to paymentResult.amountFormatted,
            "providerName" to paymentResult.providerName,
            "payeeName" to paymentResult.payeeName
        )
    }
}
```

More information on how to integrate Android SDK in an application can be found at https://github.com/banked/banked-android-sdk-examples

## iOS Integration

0. Install Flutter.
You can use the official guidelines:
https://docs.flutter.dev/get-started/install/macos
Or use Homebrew:
https://postsrc.com/code-snippets/how-to-install-flutter-on-macos-monterey

1. Use [Cocoapods](https://cocoapods.org/) to install the Banked Checkout SDK

To integrate Banked Checkout SDK into your Xcode project using CocoaPods, specify it in your Podfile:

```swift
pod ‘Banked’
```

2.  Open the file AppDelegate.swift located under Runner > Runner in the Project navigator.

Add the following code to setup the Banked SDK to initialise, send events to the common dart code and receive events from the dart code and SDK.

```swift
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
```

3. Setup the proper API key. Contact Banked for getting this information.

4. To run the app in a real device, setup Signing properly.

5. If you receive the error:
```
Error: Could not find included file ‘Generated.xcconfig’ in search paths (in target ‘Runner’)
```
Run these commands from the root directory:
```
flutter clean
flutter pub get
cd ios/
pod install
```

Try also to update your cocoapods repository running:
```
pod repo update
```

You can also check this website:
https://fluttercorner.com/solved-error-could-not-find-included-file-generated-xcconfig-in-search-paths-in-target-runner/

6. Make sure you use the latest Banked version.
`pod install` will maintain the version defined in Podfile.lock.
Running `pod update` will download the latest version, given that `Podfile` does not define a specific version.

You can run from time to time:
```
pod outdated
```
to check which pods are outdated in your project.

7. If you see the error:
```
error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation.
```
After creating a new project from scracth and trying to use cocoapods, perhaps you have to follow these steps:
https://stackoverflow.com/questions/53630136/using-cocoapods-libraries-in-flutter-ios-platform-specific-code
(Add some modifications in the .xcconfig files)





