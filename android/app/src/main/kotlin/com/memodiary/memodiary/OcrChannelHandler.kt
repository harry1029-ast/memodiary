package com.memodiary.memodiary

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Native Android MethodChannel handler for `memodiary/ocr` (ADR 0004).
 *
 * Uses bundled on-device ML Kit Chinese Text Recognition v2 (which recognizes
 * both Chinese and Latin scripts offline). `android.permission.INTERNET` and
 * `ACCESS_NETWORK_STATE` are stripped from the merged manifest via
 * `tools:node="remove"`.
 */
class OcrChannelHandler(
    private val applicationContext: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "memodiary/ocr"
    }

    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
    private val recognizer: TextRecognizer = TextRecognition.getClient(
        ChineseTextRecognizerOptions.Builder().build(),
    )
    private val decodeExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val isDisposed = AtomicBoolean(false)

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "recognize") {
            result.notImplemented()
            return
        }

        val path = call.argument<String>("path")?.trim()
        if (path.isNullOrEmpty()) {
            result.error("OCR_INVALID_ARGS", "Missing non-empty 'path' argument", null)
            return
        }

        if (isDisposed.get()) {
            result.error("OCR_DISPOSED", "OcrChannelHandler has been disposed", null)
            return
        }

        decodeExecutor.execute {
            if (isDisposed.get()) {
                mainHandler.post {
                    result.error("OCR_DISPOSED", "OcrChannelHandler has been disposed", null)
                }
                return@execute
            }

            val imageFile = File(path)
            if (!imageFile.exists() || !imageFile.isFile) {
                mainHandler.post {
                    result.error("OCR_FILE_NOT_FOUND", "Image file does not exist: $path", null)
                }
                return@execute
            }

            val inputImage: InputImage = try {
                InputImage.fromFilePath(applicationContext, Uri.fromFile(imageFile))
            } catch (decodeException: Exception) {
                mainHandler.post {
                    result.error(
                        "OCR_DECODE_FAILED",
                        decodeException.message ?: "Failed to decode image",
                        null,
                    )
                }
                return@execute
            }

            val imageWidth = inputImage.width
            val imageHeight = inputImage.height

            recognizer.process(inputImage)
                .addOnSuccessListener { visionText ->
                    val serializedLines = ArrayList<Map<String, Any>>()
                    for (textBlock in visionText.textBlocks) {
                        for (line in textBlock.lines) {
                            val box = line.boundingBox ?: continue
                            if (box.width() <= 0 || box.height() <= 0) {
                                continue
                            }
                            serializedLines.add(
                                mapOf(
                                    "text" to line.text,
                                    "left" to box.left,
                                    "top" to box.top,
                                    "width" to box.width(),
                                    "height" to box.height(),
                                ),
                            )
                        }
                    }

                    val response = mapOf(
                        "imageWidth" to imageWidth,
                        "imageHeight" to imageHeight,
                        "lines" to serializedLines,
                    )
                    mainHandler.post {
                        result.success(response)
                    }
                }
                .addOnFailureListener { recognitionException ->
                    mainHandler.post {
                        result.error(
                            "OCR_RECOGNITION_FAILED",
                            recognitionException.message ?: "ML Kit text recognition failed",
                            null,
                        )
                    }
                }
        }
    }

    fun dispose() {
        if (isDisposed.compareAndSet(false, true)) {
            methodChannel.setMethodCallHandler(null)
            recognizer.close()
            decodeExecutor.shutdown()
        }
    }
}
