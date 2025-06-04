package com.ki.king_kiosk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.kingkiosk.frame_capture.FrameCapturePlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register custom frame capture plugin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FrameCapturePlugin.CHANNEL_NAME)
            .setMethodCallHandler(FrameCapturePlugin())
    }
}
