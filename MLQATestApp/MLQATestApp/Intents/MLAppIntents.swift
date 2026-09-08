// Demonstrates: AppIntents framework for Siri and Shortcuts integration — Apple ML QA
import AppIntents
import Vision
import NaturalLanguage
import UIKit

struct ClassifyImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Classify Image"
    static var description: IntentDescription = "Classifies a synthetic test image using the Vision framework"

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let image = TestImageFactory.syntheticScene()
        guard let cgImage = image.cgImage else {
            return .result(value: "Failed to create test image")
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let topLabels = (request.results ?? [])
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
            .map { "\($0.identifier): \(String(format: "%.1f%%", $0.confidence * 100))" }
            .joined(separator: ", ")

        return .result(value: topLabels.isEmpty ? "No labels detected" : topLabels)
    }
}

struct AnalyzeSentimentIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Sentiment"
    static var description: IntentDescription = "Analyzes the sentiment of provided text"

    @Parameter(title: "Text to analyze")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        guard let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0 else {
            return .result(value: "Could not analyze sentiment")
        }

        let score = Double(tag.rawValue) ?? 0
        let label: String
        if score > 0.1 { label = "Positive" }
        else if score < -0.1 { label = "Negative" }
        else { label = "Neutral" }

        return .result(value: "\(label) (score: \(String(format: "%.3f", score)))")
    }
}

struct RunBenchmarkIntent: AppIntent {
    static var title: LocalizedStringResource = "Run ML Benchmark"
    static var description: IntentDescription = "Runs Vision and NLP benchmarks, reports latency and thermal state"

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let image = TestImageFactory.syntheticScene()
        guard let cgImage = image.cgImage else {
            return .result(value: "Failed to create test image")
        }

        // Vision benchmark
        let visionStart = CFAbsoluteTimeGetCurrent()
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let visionMs = (CFAbsoluteTimeGetCurrent() - visionStart) * 1000

        // NLP benchmark
        let nlpStart = CFAbsoluteTimeGetCurrent()
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        let sampleText = "This is a test sentence for benchmarking."
        for _ in 0..<10 {
            tagger.string = sampleText
            _ = tagger.tag(at: sampleText.startIndex, unit: .paragraph, scheme: .sentimentScore)
        }
        let nlpMs = (CFAbsoluteTimeGetCurrent() - nlpStart) * 1000

        let thermalState: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }

        return .result(value: "Vision: \(String(format: "%.1f", visionMs))ms, NLP(10x): \(String(format: "%.1f", nlpMs))ms, Thermal: \(thermalState)")
    }
}

struct ExtractTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Extract Text from Image"
    static var description: IntentDescription = "Performs OCR on a synthetic text image"

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let image = TestImageFactory.textImage("Hello from MLQATestApp Siri Intent!")
        guard let cgImage = image.cgImage else {
            return .result(value: "Failed to create test image")
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let texts = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")

        return .result(value: texts.isEmpty ? "No text detected" : texts)
    }
}

struct CheckImageQualityIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Image Quality"
    static var description: IntentDescription = "Performs a quality assessment on a synthetic image pair"

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let reference = TestImageFactory.syntheticScene()
        let degraded = TestImageFactory.noisyVersion(of: reference, intensity: 0.2)

        guard let refPixels = pixelData(from: reference),
              let testPixels = pixelData(from: degraded) else {
            return .result(value: "Failed to process images")
        }

        let count = min(refPixels.count, testPixels.count)
        var mse: Double = 0
        for i in 0..<count {
            let diff = Double(refPixels[i]) - Double(testPixels[i])
            mse += diff * diff
        }
        mse /= Double(count)

        let psnr = mse > 0 ? 10 * log10(255.0 * 255.0 / mse) : Double.infinity
        let quality: String
        if psnr > 40 { quality = "Excellent" }
        else if psnr > 30 { quality = "Good" }
        else if psnr > 20 { quality = "Fair" }
        else { quality = "Poor" }

        return .result(value: "PSNR: \(String(format: "%.1f", psnr)) dB — \(quality)")
    }

    private func pixelData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }
}

struct MLAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ClassifyImageIntent(),
            phrases: ["Classify an image with \(.applicationName)"],
            shortTitle: "Classify Image",
            systemImageName: "eye"
        )
        AppShortcut(
            intent: AnalyzeSentimentIntent(),
            phrases: ["Analyze sentiment with \(.applicationName)"],
            shortTitle: "Analyze Sentiment",
            systemImageName: "text.bubble"
        )
        AppShortcut(
            intent: RunBenchmarkIntent(),
            phrases: ["Run ML benchmark with \(.applicationName)"],
            shortTitle: "Run Benchmark",
            systemImageName: "speedometer"
        )
        AppShortcut(
            intent: ExtractTextIntent(),
            phrases: ["Extract text with \(.applicationName)"],
            shortTitle: "Extract Text",
            systemImageName: "doc.text"
        )
        AppShortcut(
            intent: CheckImageQualityIntent(),
            phrases: ["Check image quality with \(.applicationName)"],
            shortTitle: "Check Image Quality",
            systemImageName: "photo.badge.checkmark"
        )
    }
}
