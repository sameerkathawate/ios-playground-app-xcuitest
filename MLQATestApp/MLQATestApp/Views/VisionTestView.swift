// Demonstrates: Vision framework, image classification, object detection, OCR, face detection, saliency — Apple ML QA
import SwiftUI
import Vision
import PhotosUI

struct VisionTestResult: Identifiable {
    let id = UUID()
    let name: String
    var status: TestStatus = .idle
    var details: String = ""
    var latencyMs: Double = 0
    var confidence: Double = 0

    enum TestStatus: String {
        case idle = "Idle"
        case running = "Running..."
        case pass = "PASS"
        case fail = "FAIL"
    }
}

@MainActor
@Observable
final class VisionTestViewModel {
    var testImage: UIImage?
    var results: [VisionTestResult] = [
        VisionTestResult(name: "Image Classification"),
        VisionTestResult(name: "Rectangle Detection"),
        VisionTestResult(name: "Text Recognition (OCR)"),
        VisionTestResult(name: "Face & Landmark Detection"),
        VisionTestResult(name: "Attention Saliency"),
        VisionTestResult(name: "Barcode Detection")
    ]
    var isRunningAll = false
    var selectedPhotoItem: PhotosPickerItem?

    func useSampleImage() {
        testImage = TestImageFactory.syntheticScene()
    }

    func loadPhoto() async {
        guard let item = selectedPhotoItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        testImage = image
    }

    func runAllTests() async {
        guard let image = testImage else { return }
        isRunningAll = true
        for i in results.indices {
            results[i].status = .idle
        }
        await runClassification(image: image)
        await runRectangleDetection(image: image)
        await runOCR(image: image)
        await runFaceDetection(image: image)
        await runSaliency(image: image)
        await runBarcodeDetection(image: image)
        isRunningAll = false
    }

    func runClassification(image: UIImage) async {
        let idx = 0
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            results[idx].details = "No CGImage"
            return
        }

        do {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let observations = (request.results ?? [])
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)

            results[idx].latencyMs = elapsed
            if let top = observations.first {
                results[idx].confidence = Double(top.confidence)
                results[idx].details = observations
                    .map { "\($0.identifier): \(String(format: "%.1f%%", $0.confidence * 100))" }
                    .joined(separator: "\n")
                results[idx].status = top.confidence > 0.1 ? .pass : .fail
            } else {
                results[idx].details = "No results"
                results[idx].status = .fail
            }
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }

    func runRectangleDetection(image: UIImage) async {
        let idx = 1
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            return
        }

        do {
            let request = VNDetectRectanglesRequest()
            request.maximumObservations = 10
            request.minimumConfidence = 0.3
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let rects = request.results ?? []
            results[idx].latencyMs = elapsed
            results[idx].details = "Detected \(rects.count) rectangle(s)"
            if let top = rects.first {
                results[idx].confidence = Double(top.confidence)
                results[idx].details += "\nTop confidence: \(String(format: "%.1f%%", top.confidence * 100))"
                results[idx].details += "\nBounds: \(String(format: "(%.2f, %.2f, %.2f, %.2f)", top.boundingBox.origin.x, top.boundingBox.origin.y, top.boundingBox.width, top.boundingBox.height))"
            }
            results[idx].status = !rects.isEmpty ? .pass : .fail
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }

    func runOCR(image: UIImage) async {
        let idx = 2
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            return
        }

        do {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let observations = request.results ?? []
            let texts = observations.compactMap { $0.topCandidates(1).first }
            results[idx].latencyMs = elapsed
            results[idx].details = texts.map { "\($0.string) (\(String(format: "%.1f%%", $0.confidence * 100)))" }.joined(separator: "\n")
            if texts.isEmpty {
                results[idx].details = "No text detected"
            }
            results[idx].confidence = Double(texts.first?.confidence ?? 0)
            results[idx].status = !texts.isEmpty ? .pass : .fail
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }

    func runFaceDetection(image: UIImage) async {
        let idx = 3
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            return
        }

        do {
            let request = VNDetectFaceLandmarksRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let faces = request.results ?? []
            results[idx].latencyMs = elapsed
            results[idx].details = "Detected \(faces.count) face(s)"
            for (i, face) in faces.enumerated() {
                var faceInfo = "\nFace \(i+1):"
                if let landmarks = face.landmarks {
                    var count = 0
                    if landmarks.nose != nil { count += 1 }
                    if landmarks.leftEye != nil { count += 1 }
                    if landmarks.rightEye != nil { count += 1 }
                    if landmarks.outerLips != nil { count += 1 }
                    if landmarks.leftEyebrow != nil { count += 1 }
                    if landmarks.rightEyebrow != nil { count += 1 }
                    faceInfo += " \(count) landmarks"
                }
                if let roll = face.roll {
                    faceInfo += " Roll: \(String(format: "%.1f", roll.doubleValue))°"
                }
                if let yaw = face.yaw {
                    faceInfo += " Yaw: \(String(format: "%.1f", yaw.doubleValue))°"
                }
                results[idx].details += faceInfo
            }
            results[idx].confidence = faces.isEmpty ? 0 : Double(faces.first?.confidence ?? 0)
            results[idx].status = !faces.isEmpty ? .pass : .fail
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }

    func runSaliency(image: UIImage) async {
        let idx = 4
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            return
        }

        do {
            let request = VNGenerateAttentionBasedSaliencyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let observations = request.results ?? []
            results[idx].latencyMs = elapsed
            if let saliency = observations.first {
                let regions = saliency.salientObjects ?? []
                results[idx].details = "Salient regions: \(regions.count)"
                results[idx].confidence = Double(saliency.confidence)
                results[idx].status = .pass
            } else {
                results[idx].details = "No saliency data"
                results[idx].status = .fail
            }
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }

    func runBarcodeDetection(image: UIImage) async {
        let idx = 5
        results[idx].status = .running
        let start = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            results[idx].status = .fail
            return
        }

        do {
            let request = VNDetectBarcodesRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            let barcodes = request.results ?? []
            results[idx].latencyMs = elapsed
            results[idx].details = "Detected \(barcodes.count) barcode(s)"
            for barcode in barcodes {
                results[idx].details += "\nType: \(barcode.symbology.rawValue)"
                if let payload = barcode.payloadStringValue {
                    results[idx].details += " Payload: \(payload)"
                }
            }
            results[idx].confidence = barcodes.isEmpty ? 0 : Double(barcodes.first?.confidence ?? 0)
            results[idx].status = barcodes.isEmpty ? .fail : .pass
        } catch {
            results[idx].status = .fail
            results[idx].details = error.localizedDescription
        }
    }
}

struct VisionTestView: View {
    @State private var vm = VisionTestViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Test Image") {
                    if let image = vm.testImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .accessibilityIdentifier("vision_test_image")
                    }

                    HStack {
                        Button("Use Sample Image") {
                            vm.useSampleImage()
                        }
                        .accessibilityIdentifier("vision_sample_button")

                        PhotosPicker(selection: $vm.selectedPhotoItem, matching: .images) {
                            Label("Pick Photo", systemImage: "photo.on.rectangle")
                        }
                        .accessibilityIdentifier("vision_photo_picker")
                    }
                }

                Section {
                    Button(vm.isRunningAll ? "Running..." : "Run All Tests") {
                        Task { await vm.runAllTests() }
                    }
                    .disabled(vm.testImage == nil || vm.isRunningAll)
                    .accessibilityIdentifier("vision_run_all")
                } header: {
                    Text("Actions")
                }

                Section("Test Results") {
                    ForEach(vm.results) { result in
                        VisionResultRow(result: result)
                    }
                }
            }
            .navigationTitle("Vision Tests")
            .onChange(of: vm.selectedPhotoItem) {
                Task { await vm.loadPhoto() }
            }
        }
    }
}

struct VisionResultRow: View {
    let result: VisionTestResult

    var statusColor: Color {
        switch result.status {
        case .idle: return .secondary
        case .running: return .orange
        case .pass: return .green
        case .fail: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.name)
                    .font(.headline)
                Spacer()
                Text(result.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .accessibilityIdentifier("vision_status_\(result.name)")
            }

            if result.latencyMs > 0 {
                HStack {
                    Text("\(String(format: "%.1f", result.latencyMs)) ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if result.confidence > 0 {
                        ProgressView(value: result.confidence, total: 1.0)
                            .tint(result.confidence > 0.5 ? .green : .orange)
                        Text("\(String(format: "%.1f%%", result.confidence * 100))")
                            .font(.caption2)
                    }
                }
            }

            if !result.details.isEmpty && result.status != .idle {
                Text(result.details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                    .accessibilityIdentifier("vision_details_\(result.name)")
            }
        }
        .padding(.vertical, 4)
    }
}
