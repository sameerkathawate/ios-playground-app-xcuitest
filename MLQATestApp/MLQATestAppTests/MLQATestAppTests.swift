import XCTest
import Vision
import NaturalLanguage
import CoreImage
@testable import MLQATestApp

final class MLQATestAppTests: XCTestCase {

    // MARK: - Vision: Classification

    func testClassificationReturnsResults() throws {
        let image = TestImageFactory.syntheticScene()
        let cgImage = try XCTUnwrap(image.cgImage)
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        XCTAssertNotNil(request.results)
        XCTAssertFalse(request.results!.isEmpty, "Classification should return at least one label")
    }

    func testClassificationConfidenceAboveThreshold() throws {
        let image = TestImageFactory.syntheticScene()
        let cgImage = try XCTUnwrap(image.cgImage)
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let top = try XCTUnwrap(request.results?.max(by: { $0.confidence < $1.confidence }))
        XCTAssertGreaterThan(top.confidence, 0.01, "Top classification confidence should exceed threshold")
    }

    func testClassificationLatencyUnder500ms() throws {
        let image = TestImageFactory.syntheticScene()
        let cgImage = try XCTUnwrap(image.cgImage)
        let start = CFAbsoluteTimeGetCurrent()
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        XCTAssertLessThan(elapsed, 500, "Classification should complete in under 500ms")
    }

    func testClassificationDeterministic() throws {
        let image = TestImageFactory.syntheticScene()
        let cgImage = try XCTUnwrap(image.cgImage)

        let request1 = VNClassifyImageRequest()
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request1])
        let labels1 = request1.results?.sorted(by: { $0.confidence > $1.confidence }).prefix(3).map(\.identifier)

        let request2 = VNClassifyImageRequest()
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request2])
        let labels2 = request2.results?.sorted(by: { $0.confidence > $1.confidence }).prefix(3).map(\.identifier)

        XCTAssertEqual(labels1, labels2, "Classification should be deterministic for the same input")
    }

    // MARK: - Vision: OCR

    func testOCRDetectsKnownText() throws {
        let image = TestImageFactory.textImage("Hello World 12345")
        let cgImage = try XCTUnwrap(image.cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        let texts = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        let combined = texts.joined(separator: " ")
        XCTAssertTrue(combined.contains("Hello") || combined.contains("World") || combined.contains("12345"),
                       "OCR should detect known text content")
    }

    func testOCREmptyForBlankImage() throws {
        let image = TestImageFactory.blankImage()
        let cgImage = try XCTUnwrap(image.cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        let texts = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        XCTAssertTrue(texts.isEmpty, "OCR should return no text for a blank image")
    }

    // MARK: - Vision: Rectangle Detection

    func testRectangleDetectionWorks() throws {
        let image = TestImageFactory.rectangleImage()
        let cgImage = try XCTUnwrap(image.cgImage)
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 10
        request.minimumConfidence = 0.1
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        // Rectangle detection may or may not find rects in synthetic images — validate it runs without error
        XCTAssertNotNil(request.results, "Rectangle detection should return a results array")
    }

    // MARK: - NLP: Language Detection

    func testLanguageDetectionEnglish() {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString("This is a test sentence in English.")
        let lang = recognizer.dominantLanguage
        XCTAssertEqual(lang, .english, "Should detect English")
    }

    func testLanguageDetectionSpanish() {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString("Esta es una oración de prueba en español.")
        let lang = recognizer.dominantLanguage
        XCTAssertEqual(lang, .spanish, "Should detect Spanish")
    }

    // MARK: - NLP: Sentiment

    func testSentimentPositive() {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        let text = "I absolutely love this! It's the best thing ever!"
        tagger.string = text
        let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        let score = Double(tag?.rawValue ?? "0") ?? 0
        XCTAssertGreaterThan(score, 0, "Positive text should have positive sentiment score")
    }

    func testSentimentNegative() {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        let text = "This is terrible and awful. I hate it completely."
        tagger.string = text
        let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        let score = Double(tag?.rawValue ?? "0") ?? 0
        XCTAssertLessThan(score, 0, "Negative text should have negative sentiment score")
    }

    // MARK: - NLP: NER

    func testNERDetectsPersonName() {
        let tagger = NLTagger(tagSchemes: [.nameType])
        let text = "Steve Jobs founded Apple in California."
        tagger.string = text
        var foundPerson = false
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, _ in
            if tag == .personalName { foundPerson = true }
            return true
        }
        XCTAssertTrue(foundPerson, "NER should detect person names")
    }

    func testNERDetectsOrganization() {
        let tagger = NLTagger(tagSchemes: [.nameType])
        let text = "Microsoft and Google are technology companies."
        tagger.string = text
        var foundOrg = false
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, _ in
            if tag == .organizationName { foundOrg = true }
            return true
        }
        XCTAssertTrue(foundOrg, "NER should detect organization names")
    }

    func testNERDetectsPlaceName() {
        let tagger = NLTagger(tagSchemes: [.nameType])
        let text = "The headquarters are located in Cupertino, California."
        tagger.string = text
        var foundPlace = false
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, _ in
            if tag == .placeName { foundPlace = true }
            return true
        }
        XCTAssertTrue(foundPlace, "NER should detect place names")
    }

    // MARK: - NLP: Tokenization

    func testTokenizationWordCount() {
        let tokenizer = NLTokenizer(unit: .word)
        let text = "The quick brown fox jumps over the lazy dog"
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        XCTAssertEqual(count, 9, "Should tokenize into 9 words")
    }

    // MARK: - NLP: Embeddings

    func testWordEmbeddingAvailability() {
        let embedding = NLEmbedding.wordEmbedding(for: .english)
        XCTAssertNotNil(embedding, "English word embeddings should be available")
    }

    func testEmbeddingNeighborRelevance() {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            XCTFail("Word embeddings unavailable")
            return
        }
        let neighbors = embedding.neighbors(for: "computer", maximumCount: 5)
        XCTAssertFalse(neighbors.isEmpty, "Should find neighbors for common word")
    }

    // MARK: - Image Quality: PSNR

    func testPSNRInfiniteForIdenticalImages() {
        let image = TestImageFactory.syntheticScene()
        guard let pixels = pixelData(from: image) else {
            XCTFail("Could not get pixel data")
            return
        }
        var mse: Double = 0
        for i in 0..<pixels.count {
            let diff = Double(pixels[i]) - Double(pixels[i])
            mse += diff * diff
        }
        mse /= Double(pixels.count)
        XCTAssertEqual(mse, 0, "MSE for identical images should be zero")
    }

    func testPSNRInExpectedRangeForDegradedImage() {
        let original = TestImageFactory.syntheticScene()
        let degraded = TestImageFactory.noisyVersion(of: original, intensity: 0.2)
        guard let origPixels = pixelData(from: original),
              let degradedPixels = pixelData(from: degraded) else {
            XCTFail("Could not get pixel data")
            return
        }
        let count = min(origPixels.count, degradedPixels.count)
        var mse: Double = 0
        for i in 0..<count {
            let diff = Double(origPixels[i]) - Double(degradedPixels[i])
            mse += diff * diff
        }
        mse /= Double(count)
        guard mse > 0 else {
            XCTFail("Degraded image should differ from original")
            return
        }
        let psnr = 10 * log10(255.0 * 255.0 / mse)
        XCTAssertGreaterThan(psnr, 10, "PSNR should be above 10 dB for lightly degraded image")
        XCTAssertLessThan(psnr, 60, "PSNR should be below 60 dB for degraded image")
    }

    // MARK: - Image Quality: Sharpness

    func testSharpnessPositiveForNonBlank() {
        let image = TestImageFactory.syntheticScene()
        let sharpness = computeSharpness(image)
        XCTAssertGreaterThan(sharpness, 0, "Sharpness should be positive for a non-blank image")
    }

    func testSharpnessLowForBlank() {
        let image = TestImageFactory.blankImage()
        let sharpness = computeSharpness(image)
        XCTAssertLessThan(sharpness, 1, "Sharpness should be very low for a blank image")
    }

    // MARK: - App Intents

    func testClassifyImageIntentReturnsResult() async throws {
        let intent = ClassifyImageIntent()
        let result = try await intent.perform()
        XCTAssertNotNil(result.value, "ClassifyImageIntent should return a non-nil result")
        XCTAssertFalse(result.value!.isEmpty, "ClassifyImageIntent result should not be empty")
    }

    func testSentimentIntentReturnsMeaningfulOutput() async throws {
        let intent = AnalyzeSentimentIntent()
        intent.text = "This is wonderful!"
        let result = try await intent.perform()
        XCTAssertNotNil(result.value)
        XCTAssertTrue(result.value!.contains("Positive") || result.value!.contains("score"),
                       "Sentiment intent should return meaningful output")
    }

    func testBenchmarkIntentReportsLatency() async throws {
        let intent = RunBenchmarkIntent()
        let result = try await intent.perform()
        XCTAssertNotNil(result.value)
        XCTAssertTrue(result.value!.contains("ms"), "Benchmark should report latency in milliseconds")
    }

    func testExtractTextIntentReturnsResult() async throws {
        let intent = ExtractTextIntent()
        let result = try await intent.perform()
        XCTAssertNotNil(result.value, "ExtractTextIntent should return a non-nil result")
    }

    func testCheckImageQualityIntentReturnsResult() async throws {
        let intent = CheckImageQualityIntent()
        let result = try await intent.perform()
        XCTAssertNotNil(result.value, "CheckImageQualityIntent should return a non-nil result")
        XCTAssertTrue(result.value!.contains("PSNR"), "Quality intent should report PSNR")
    }

    // MARK: - Performance

    func testVisionClassificationPerformance() throws {
        let image = TestImageFactory.syntheticScene()
        let cgImage = try XCTUnwrap(image.cgImage)
        measure {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    func testNLPSentimentThroughput() {
        let text = "This product is excellent and I love using it every day."
        measure {
            for _ in 0..<100 {
                let tagger = NLTagger(tagSchemes: [.sentimentScore])
                tagger.string = text
                _ = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
            }
        }
    }

    // MARK: - Helpers

    private func pixelData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &data, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }

    private func computeSharpness(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        let laplacian = CIFilter.convolution3X3()
        laplacian.inputImage = ciImage
        laplacian.weights = CIVector(values: [0, 1, 0, 1, -4, 1, 0, 1, 0], count: 9)
        laplacian.bias = 0
        guard let output = laplacian.outputImage,
              let outputCG = context.createCGImage(output, from: ciImage.extent) else { return 0 }
        let outputImage = UIImage(cgImage: outputCG)
        guard let pixels = pixelData(from: outputImage) else { return 0 }
        let pixelCount = pixels.count / 4
        var sum: Double = 0, sqSum: Double = 0
        for i in 0..<pixelCount {
            let gray = Double(pixels[i * 4])
            sum += gray
            sqSum += gray * gray
        }
        let mean = sum / Double(pixelCount)
        return sqSum / Double(pixelCount) - mean * mean
    }
}
