package com.example.banked_flutter_sdk_example

import android.os.Bundle
import com.banked.checkout.Banked
import com.banked.checkout.OnPaymentSessionListener
import com.banked.checkout.feature.status.model.PaymentResult
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
