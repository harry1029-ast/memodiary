package com.memodiary.memodiary

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var ocrChannelHandler: OcrChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrChannelHandler = OcrChannelHandler(
            applicationContext = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ocrChannelHandler?.dispose()
        ocrChannelHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
