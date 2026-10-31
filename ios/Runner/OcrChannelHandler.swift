import Flutter
import ImageIO
import UIKit
import Vision

/// Native iOS MethodChannel handler for `memodiary/ocr` (ADR 0004).
///
/// Uses Apple's built-in Vision framework (`VNRecognizeTextRequest`) targeting
/// iOS 15.0+ with Simplified Chinese, Traditional Chinese, and English
/// recognition languages, converting bottom-left normalized coordinates into
/// top-left pixel coordinates matching the shared Dart normalizer contract.
final class OcrChannelHandler: NSObject, FlutterPlugin {
  static let channelName = "memodiary/ocr"

  private let recognitionQueue = DispatchQueue(
    label: "com.memodiary.memodiary.ocr",
    qos: .utility
  )

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = OcrChannelHandler()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let rawPath = args["path"] as? String
    else {
      result(
        FlutterError(
          code: "OCR_INVALID_ARGS",
          message: "Missing non-empty 'path' argument",
          details: nil
        )
      )
      return
    }

    let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
    if path.isEmpty {
      result(
        FlutterError(
          code: "OCR_INVALID_ARGS",
          message: "Empty 'path' argument",
          details: nil
        )
      )
      return
    }

    recognitionQueue.async {
      self.recognizeImage(atPath: path, result: result)
    }
  }

  private func recognizeImage(atPath path: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      DispatchQueue.main.async {
        result(
          FlutterError(
            code: "OCR_FILE_NOT_FOUND",
            message: "Image file does not exist: \(path)",
            details: nil
          )
        )
      }
      return
    }

    guard
      let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
      DispatchQueue.main.async {
        result(
          FlutterError(
            code: "OCR_DECODE_FAILED",
            message: "Unable to decode CGImage at \(path)",
            details: nil
          )
        )
      }
      return
    }

    let orientation = Self.extractOrientation(from: imageSource)
    let swapsDimensions = Self.orientationSwapsDimensions(orientation)
    let orientedWidth = Double(swapsDimensions ? cgImage.height : cgImage.width)
    let orientedHeight = Double(swapsDimensions ? cgImage.width : cgImage.height)

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

    let handler = VNImageRequestHandler(
      cgImage: cgImage,
      orientation: orientation,
      options: [:]
    )

    do {
      try handler.perform([request])
    } catch {
      DispatchQueue.main.async {
        result(
          FlutterError(
            code: "OCR_RECOGNITION_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
      return
    }

    let observations = request.results ?? []
    var serializedLines: [[String: Any]] = []
    serializedLines.reserveCapacity(observations.count)

    for observation in observations {
      guard let topCandidate = observation.topCandidates(1).first else {
        continue
      }
      let text = topCandidate.string
      if text.isEmpty {
        continue
      }

      // Vision boundingBox uses bottom-left origin in [0, 1] x [0, 1].
      // Convert to top-left pixel coordinates for OcrResultNormalizer.
      let box = observation.boundingBox
      let leftPx = Double(box.minX) * orientedWidth
      let topPx = Double(1.0 - box.maxY) * orientedHeight
      let widthPx = Double(box.width) * orientedWidth
      let heightPx = Double(box.height) * orientedHeight

      if widthPx <= 0 || heightPx <= 0 {
        continue
      }

      serializedLines.append([
        "text": text,
        "left": leftPx,
        "top": topPx,
        "width": widthPx,
        "height": heightPx,
      ])
    }

    let payload: [String: Any] = [
      "imageWidth": Int(orientedWidth.rounded()),
      "imageHeight": Int(orientedHeight.rounded()),
      "lines": serializedLines,
    ]

    DispatchQueue.main.async {
      result(payload)
    }
  }

  private static func extractOrientation(
    from imageSource: CGImageSource
  ) -> CGImagePropertyOrientation {
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
      let rawOrientation = properties[kCGImagePropertyOrientation] as? UInt32,
      let orientation = CGImagePropertyOrientation(rawValue: rawOrientation)
    else {
      return .up
    }
    return orientation
  }

  private static func orientationSwapsDimensions(
    _ orientation: CGImagePropertyOrientation
  ) -> Bool {
    switch orientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      return true
    case .up, .upMirrored, .down, .downMirrored:
      return false
    }
  }
}
