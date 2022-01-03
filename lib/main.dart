import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const methodChannel =
      const MethodChannel('com.example.banked_flutter_sdk_example/banked_sdk');
  String _sdkStatus = 'Click button to start the SDK';

  _MyHomePageState() {
    methodChannel.setMethodCallHandler((call) => _processSdkCallback(call));
  }

  Future<dynamic> _processSdkCallback(MethodCall call) async {
    print("Call - " + call.method);

    String newStatus = "Unknown";

    if (call.method == "BankedSdkPaymentSuccess") {
      newStatus = _buildPaymentStatusText("Payment Success", call);
    } else if (call.method == "BankedSdkPaymentFailed") {
      newStatus = _buildPaymentStatusText("Payment Failed", call);
    } else if (call.method == "BankedSdkPaymentAborted") {
      newStatus = "Payment Aborted";
    }

    setState(() {
      _sdkStatus = newStatus;
    });
  }

  String _buildPaymentStatusText(String prefixStatus, MethodCall call) {
    return prefixStatus +
        "\nProvider Name: " +
        call.arguments["providerName"] +
        "\nPayee Name: " +
        call.arguments["payeeName"] +
        "\nAmount Formatted: " +
        call.arguments["amountFormatted"];
  }

  Future<void> _startBankedSdk() async {
    String sdkStatus;
    try {
      final Map params = <String, dynamic>{
        'payment id': "XXXXXXXX-XXXX-XXXX-XXXXX-XXXXXXXXXXX",
        'continue url': "XXXXXXXXXXX",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: _startBankedSdk,
              child: Text('Start Banked SDK'),
            ),
            Text(_sdkStatus)
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
