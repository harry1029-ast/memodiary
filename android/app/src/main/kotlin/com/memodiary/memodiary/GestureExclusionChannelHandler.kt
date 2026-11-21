package com.memodiary.memodiary

import android.graphics.Rect
import android.os.Build
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * Native Android MethodChannel handler for `memodiary/gesture_exclusion`
 * (SPEC-023, ADR 0014).
 *
 * Flutter has no public API for Android system gesture exclusion, so the Home
 * Shell reports its left-edge Diarist Panel drag band here and this handler
 * applies it to the Flutter view with `View.setSystemGestureExclusionRects`.
 * Android honours at most 200dp of exclusion per edge.
 *
 * - `setRect` {left, top, width, height} in logical pixels (dp): replaces the
 *   exclusion with that one rect.
 * - `clear`: removes every exclusion rect.
 *
 * Gesture exclusion exists from Android 10 (API 29); below that both methods
 * succeed without effect. Needs no permission and no network.
 */
class GestureExclusionChannelHandler(
    messenger: BinaryMessenger,
    private val targetView: () -> View?,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "memodiary/gesture_exclusion"
    }

    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setRect" -> {
                val left = call.argument<Number>("left")?.toDouble()
                val top = call.argument<Number>("top")?.toDouble()
                val width = call.argument<Number>("width")?.toDouble()
                val height = call.argument<Number>("height")?.toDouble()
                if (left == null || top == null || width == null || height == null) {
                    result.error("GESTURE_EXCLUSION_INVALID_ARGS", "Missing left/top/width/height", null)
                    return
                }
                applyRects { density ->
                    listOf(
                        Rect(
                            (left * density).roundToInt(),
                            (top * density).roundToInt(),
                            ((left + width) * density).roundToInt(),
                            ((top + height) * density).roundToInt(),
                        ),
                    )
                }
                result.success(null)
            }
            "clear" -> {
                applyRects { emptyList() }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun applyRects(rectsFor: (density: Float) -> List<Rect>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val view = targetView() ?: return
        view.systemGestureExclusionRects = rectsFor(view.resources.displayMetrics.density)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        applyRects { emptyList() }
    }
}
