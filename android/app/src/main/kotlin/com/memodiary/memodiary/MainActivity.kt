package com.memodiary.memodiary

import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var ocrChannelHandler: OcrChannelHandler? = null
    private var gestureExclusionChannelHandler: GestureExclusionChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrChannelHandler = OcrChannelHandler(
            applicationContext = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        gestureExclusionChannelHandler = GestureExclusionChannelHandler(
            messenger = flutterEngine.dartExecutor.binaryMessenger,
            targetView = { findViewById<View>(FLUTTER_VIEW_ID) },
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ocrChannelHandler?.dispose()
        ocrChannelHandler = null
        gestureExclusionChannelHandler?.dispose()
        gestureExclusionChannelHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
