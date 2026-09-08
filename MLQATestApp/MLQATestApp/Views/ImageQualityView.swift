// Demonstrates: Image quality metrics (PSNR, sharpness, noise, color science), CoreImage — Apple ML QA
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI

struct QualityMetric: Identifiable {
    let id = UUID()
    let name: String
    var value: String = ""
    var level: QualityLevel = .none
    var details: String = ""

    enum QualityLevel: String {
        case none = ""
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }
}

@MainActor
@Observable
final class ImageQualityViewModel {
    var referenceImage: UIImage?
    var testImage: UIImage?
    var referencePhotoItem: PhotosPickerItem?
    var testPhotoItem: PhotosPickerItem?
    var metrics: [QualityMetric] = [
        QualityMetric(name: "PSNR"),
        QualityMetric(name: "Difference Map"),
        QualityMetric(name: "Histogram Analysis"),
        QualityMetric(name: "Noise Estimation"),
        QualityMetric(name: "Sharpness"),
        QualityMetric(name: "Color Space Stats")
    ]
    var differenceMapImage: UIImage?
    var isRunning = false

    func generateReferencePair() {
        referenceImage = TestImageFactory.syntheticScene()
        testImage = TestImageFactory.noisyVersion(of: TestImageFactory.blurredVersion(of: referenceImage!, radius: 3), intensity: 0.15)
    }

    func loadReferencePhoto() async {
        guard let item = referencePhotoItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        referenceImage = image
    }

    func loadTestPhoto() async {
        guard let item = testPhotoItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        testImage = image
    }

    func runAllMetrics() async {
        guard let ref = referenceImage, let test = testImage else { return }
        isRunning = true

        computePSNR(reference: ref, test: test)
        computeDifferenceMap(reference: ref, test: test)
        computeHistogram(image: test)
        estimateNoise(image: test)
        computeSharpness(image: test)
        computeColorStats(image: test)

        isRunning = false
    }

    private func computePSNR(reference: UIImage, test: UIImage) {
        let idx = 0
        guard let refPixels = pixelData(from: reference),
              let testPixels = pixelData(from: test) else {
            metrics[idx].value = "Error"
            metrics[idx].level = .poor
            return
        }

        let count = min(refPixels.count, testPixels.count)
        guard count > 0 else {
            metrics[idx].value = "Error: no pixels"
            metrics[idx].level = .poor
            return
        }

        var mse: Double = 0
        for i in 0..<count {
            let diff = Double(refPixels[i]) - Double(testPixels[i])
            mse += diff * diff
        }
        mse /= Double(count)

        if mse == 0 {
            metrics[idx].value = "∞ dB (identical)"
            metrics[idx].level = .excellent
            metrics[idx].details = "Images are pixel-identical"
            return
        }

        let psnr = 10 * log10(255.0 * 255.0 / mse)
        metrics[idx].value = String(format: "%.2f dB", psnr)

        if psnr > 40 {
            metrics[idx].level = .excellent
            metrics[idx].details = "Imperceptible difference"
        } else if psnr > 30 {
            metrics[idx].level = .good
            metrics[idx].details = "Minor visible difference"
        } else if psnr > 20 {
            metrics[idx].level = .fair
            metrics[idx].details = "Noticeable degradation"
        } else {
            metrics[idx].level = .poor
            metrics[idx].details = "Significant quality loss"
        }
    }

    private func computeDifferenceMap(reference: UIImage, test: UIImage) {
        let idx = 1
        guard let refCG = reference.cgImage, let testCG = test.cgImage else {
            metrics[idx].value = "Error"
            return
        }

        let ciRef = CIImage(cgImage: refCG)
        let ciTest = CIImage(cgImage: testCG)
        let context = CIContext()

        let filter = CIFilter.differenceBlendMode()
        filter.inputImage = ciTest
        filter.backgroundImage = ciRef

        if let output = filter.outputImage,
           let cgResult = context.createCGImage(output, from: ciRef.extent) {
            differenceMapImage = UIImage(cgImage: cgResult)
            metrics[idx].value = "Generated"
            metrics[idx].level = .good
            metrics[idx].details = "Visual difference map available below"
        } else {
            metrics[idx].value = "Failed"
            metrics[idx].level = .poor
        }
    }

    private func computeHistogram(image: UIImage) {
        let idx = 2
        guard let pixels = pixelData(from: image) else {
            metrics[idx].value = "Error"
            return
        }

        var rSum: Double = 0, gSum: Double = 0, bSum: Double = 0
        var rSqSum: Double = 0, gSqSum: Double = 0, bSqSum: Double = 0
        var rMin: UInt8 = 255, rMax: UInt8 = 0
        var gMin: UInt8 = 255, gMax: UInt8 = 0
        var bMin: UInt8 = 255, bMax: UInt8 = 0

        let pixelCount = pixels.count / 4
        for i in 0..<pixelCount {
            let r = pixels[i * 4]
            let g = pixels[i * 4 + 1]
            let b = pixels[i * 4 + 2]

            rSum += Double(r); gSum += Double(g); bSum += Double(b)
            rSqSum += Double(r) * Double(r)
            gSqSum += Double(g) * Double(g)
            bSqSum += Double(b) * Double(b)
            rMin = min(rMin, r); rMax = max(rMax, r)
            gMin = min(gMin, g); gMax = max(gMax, g)
            bMin = min(bMin, b); bMax = max(bMax, b)
        }

        let n = Double(pixelCount)
        let rMean = rSum / n, gMean = gSum / n, bMean = bSum / n
        let rStd = sqrt(rSqSum / n - rMean * rMean)
        let gStd = sqrt(gSqSum / n - gMean * gMean)
        let bStd = sqrt(bSqSum / n - bMean * bMean)

        metrics[idx].value = String(format: "R:%.0f G:%.0f B:%.0f", rMean, gMean, bMean)
        metrics[idx].level = .good
        metrics[idx].details = """
        R: mean=\(String(format: "%.1f", rMean)) std=\(String(format: "%.1f", rStd)) range=[\(rMin)-\(rMax)]
        G: mean=\(String(format: "%.1f", gMean)) std=\(String(format: "%.1f", gStd)) range=[\(gMin)-\(gMax)]
        B: mean=\(String(format: "%.1f", bMean)) std=\(String(format: "%.1f", bStd)) range=[\(bMin)-\(bMax)]
        Dynamic range: R=\(rMax - rMin) G=\(gMax - gMin) B=\(bMax - bMin)
        """
    }

    private func estimateNoise(image: UIImage) {
        let idx = 3
        guard let cgImage = image.cgImage else {
            metrics[idx].value = "Error"
            return
        }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        // Laplacian kernel for noise estimation
        let laplacian = CIFilter.convolution3X3()
        laplacian.inputImage = ciImage
        laplacian.weights = CIVector(values: [0, 1, 0, 1, -4, 1, 0, 1, 0], count: 9)
        laplacian.bias = 0

        guard let output = laplacian.outputImage,
              let outputCG = context.createCGImage(output, from: ciImage.extent) else {
            metrics[idx].value = "Failed"
            metrics[idx].level = .poor
            return
        }

        let outputImage = UIImage(cgImage: outputCG)
        guard let pixels = pixelData(from: outputImage) else {
            metrics[idx].value = "Failed"
            return
        }

        let pixelCount = pixels.count / 4
        var sum: Double = 0
        var sqSum: Double = 0
        for i in 0..<pixelCount {
            let gray = Double(pixels[i * 4])
            sum += gray
            sqSum += gray * gray
        }
        let mean = sum / Double(pixelCount)
        let variance = sqSum / Double(pixelCount) - mean * mean
        let sigma = sqrt(max(0, variance))

        metrics[idx].value = String(format: "σ = %.2f", sigma)
        if sigma < 5 {
            metrics[idx].level = .excellent
            metrics[idx].details = "Very clean image"
        } else if sigma < 15 {
            metrics[idx].level = .good
            metrics[idx].details = "Low noise level"
        } else if sigma < 30 {
            metrics[idx].level = .fair
            metrics[idx].details = "Moderate noise"
        } else {
            metrics[idx].level = .poor
            metrics[idx].details = "High noise level"
        }
    }

    private func computeSharpness(image: UIImage) {
        let idx = 4
        guard let cgImage = image.cgImage else {
            metrics[idx].value = "Error"
            return
        }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        let laplacian = CIFilter.convolution3X3()
        laplacian.inputImage = ciImage
        laplacian.weights = CIVector(values: [0, 1, 0, 1, -4, 1, 0, 1, 0], count: 9)
        laplacian.bias = 0

        guard let output = laplacian.outputImage,
              let outputCG = context.createCGImage(output, from: ciImage.extent) else {
            metrics[idx].value = "Failed"
            return
        }

        let outputImage = UIImage(cgImage: outputCG)
        guard let pixels = pixelData(from: outputImage) else {
            metrics[idx].value = "Failed"
            return
        }

        let pixelCount = pixels.count / 4
        var sum: Double = 0
        var sqSum: Double = 0
        for i in 0..<pixelCount {
            let gray = Double(pixels[i * 4])
            sum += gray
            sqSum += gray * gray
        }
        let mean = sum / Double(pixelCount)
        let variance = sqSum / Double(pixelCount) - mean * mean

        metrics[idx].value = String(format: "%.2f", variance)
        if variance > 500 {
            metrics[idx].level = .excellent
            metrics[idx].details = "Very sharp image"
        } else if variance > 100 {
            metrics[idx].level = .good
            metrics[idx].details = "Acceptably sharp"
        } else if variance > 30 {
            metrics[idx].level = .fair
            metrics[idx].details = "Slightly blurry"
        } else {
            metrics[idx].level = .poor
            metrics[idx].details = "Blurry image"
        }
    }

    private func computeColorStats(image: UIImage) {
        let idx = 5
        guard let pixels = pixelData(from: image) else {
            metrics[idx].value = "Error"
            return
        }

        let pixelCount = pixels.count / 4
        var rSum: Double = 0, gSum: Double = 0, bSum: Double = 0
        for i in 0..<pixelCount {
            rSum += Double(pixels[i * 4])
            gSum += Double(pixels[i * 4 + 1])
            bSum += Double(pixels[i * 4 + 2])
        }
        let n = Double(pixelCount)
        let rMean = rSum / n, gMean = gSum / n, bMean = bSum / n
        let avgBrightness = (rMean + gMean + bMean) / 3

        var colorCast = "Neutral"
        let threshold = 15.0
        if rMean - avgBrightness > threshold { colorCast = "Warm (red cast)" }
        else if bMean - avgBrightness > threshold { colorCast = "Cool (blue cast)" }
        else if gMean - avgBrightness > threshold { colorCast = "Green cast" }

        let rRatio = rMean / max(bMean, 1)
        let whiteBalance: String
        if abs(rRatio - 1.0) < 0.15 { whiteBalance = "Neutral" }
        else if rRatio > 1.15 { whiteBalance = "Warm" }
        else { whiteBalance = "Cool" }

        metrics[idx].value = colorCast
        metrics[idx].level = colorCast == "Neutral" ? .excellent : .fair
        metrics[idx].details = """
        R avg: \(String(format: "%.1f", rMean))
        G avg: \(String(format: "%.1f", gMean))
        B avg: \(String(format: "%.1f", bMean))
        Brightness: \(String(format: "%.1f", avgBrightness))
        White balance: \(whiteBalance) (R/B ratio: \(String(format: "%.2f", rRatio)))
        Color cast: \(colorCast)
        """
    }

    private func pixelData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }
}

struct ImageQualityView: View {
    @State private var vm = ImageQualityViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Reference Image") {
                    if let image = vm.referenceImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .accessibilityIdentifier("iq_reference_image")
                    }
                    PhotosPicker(selection: $vm.referencePhotoItem, matching: .images) {
                        Label("Pick Reference", systemImage: "photo")
                    }
                    .accessibilityIdentifier("iq_reference_picker")
                }

                Section("Test Image") {
                    if let image = vm.testImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .accessibilityIdentifier("iq_test_image")
                    }
                    PhotosPicker(selection: $vm.testPhotoItem, matching: .images) {
                        Label("Pick Test Image", systemImage: "photo")
                    }
                    .accessibilityIdentifier("iq_test_picker")
                }

                Section {
                    Button("Generate Reference Pair") {
                        vm.generateReferencePair()
                    }
                    .accessibilityIdentifier("iq_generate_pair")

                    Button(vm.isRunning ? "Analyzing..." : "Run All Metrics") {
                        Task { await vm.runAllMetrics() }
                    }
                    .disabled(vm.referenceImage == nil || vm.testImage == nil || vm.isRunning)
                    .accessibilityIdentifier("iq_run_all")
                }

                Section("Quality Metrics") {
                    ForEach(vm.metrics) { metric in
                        QualityMetricRow(metric: metric)
                    }
                }

                if let diffImage = vm.differenceMapImage {
                    Section("Difference Map") {
                        Image(uiImage: diffImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .accessibilityIdentifier("iq_difference_map")
                    }
                }
            }
            .navigationTitle("Image Quality")
            .onChange(of: vm.referencePhotoItem) {
                Task { await vm.loadReferencePhoto() }
            }
            .onChange(of: vm.testPhotoItem) {
                Task { await vm.loadTestPhoto() }
            }
        }
    }
}

struct QualityMetricRow: View {
    let metric: QualityMetric

    var levelColor: Color {
        switch metric.level {
        case .none: return .secondary
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.name).font(.headline)
                Spacer()
                if !metric.level.rawValue.isEmpty {
                    Text(metric.level.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(levelColor)
                        .accessibilityIdentifier("iq_level_\(metric.name)")
                }
            }
            if !metric.value.isEmpty {
                Text(metric.value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("iq_value_\(metric.name)")
            }
            if !metric.details.isEmpty {
                Text(metric.details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(8)
            }
        }
        .padding(.vertical, 2)
    }
}
