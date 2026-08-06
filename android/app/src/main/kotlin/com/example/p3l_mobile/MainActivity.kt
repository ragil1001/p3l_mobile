package com.example.p3l_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val captureChannel = "com.example.p3l_mobile/capture"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, captureChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCaptureScreen" -> {
                        result.success(intent.getStringExtra("capture_screen") ?: "pembeli")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
