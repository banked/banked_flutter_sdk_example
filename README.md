# Banked Flutter SDK Example

Here is an example project on how to integrate the existing native Android and iOS SDKs into a Flutter app.

## Android Integration

1. Add the latest gradle dependency into the Android app module build file

```
implementation "com.banked:checkout:2.0.0-rc1"
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
        Banked.onPaymentSessionListener = this
        Banked.apiKey = BANKED_API_KEY
    }

    override fun onDestroy() {
        Banked.onPaymentSessionListener = null
        super.onDestroy()
    }

    override fun onStart() {
        super.onStart()
        Banked.onStart(activity = this)
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
                        activity = this,
                        paymentId = paymentId,
                        continueUrl = continueUrl
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

TODO

Information on iOS integration can be found at https://flutter.dev/docs/development/platform-integration/platform-channels#step-4-add-an-ios-platform-specific-implementation