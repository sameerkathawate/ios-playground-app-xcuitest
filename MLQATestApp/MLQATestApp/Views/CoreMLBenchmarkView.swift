// Demonstrates: CoreML performance benchmarking, device profiling, stress testing — Apple ML QA
import SwiftUI
import CoreML
import Vision
import NaturalLanguage

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let name: String
    var latencyMs: Double = 0
    var memoryDeltaMB: Double = 0
    var status: String = "Idle"
    var details: String = ""
}

struct StressTestStats {
    var mean: Double = 0
    var median: Double = 0
    var p95: Double = 0
    var p99: Double = 0
    var stddev: Double = 0
    var min: Double = 0
    var max: Double = 0
    var count: Int = 0
}

@MainActor
@Observable
final class CoreMLBenchmarkViewModel {
    var deviceModel: String = ""
    var osVersion: String = ""
    var thermalState: String = ""
    var thermalEmoji: String = ""
    var processorCount: Int = 0
    var physicalMemoryGB: Double = 0
    var usedMemoryMB: Double = 0

    var benchmarks: [BenchmarkResult] = [
        BenchmarkResult(name: "Vision Classification"),
        BenchmarkResult(name: "Vision OCR"),
        BenchmarkResult(name: "NLP Sentiment (100x)"),
        BenchmarkResult(name: "Embedding Lookup")
    ]

    var discoveredModels: [(String, String)] = []
    var isRunning = false

    var stressIterations: Double = 100
    var stressStats: StressTestStats?
    var isStressTesting = false

    func loadDeviceInfo() {
        deviceModel = deviceModelName()
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        processorCount = ProcessInfo.processInfo.processorCount
        physicalMemoryGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824

        updateThermalState()
        updateMemoryUsage()
    }

    func updateThermalState() {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            thermalState = "Nominal"
            thermalEmoji = "🟢"
        case .fair:
            thermalState = "Fair"
            thermalEmoji = "🟡"
        case .serious:
            thermalState = "Serious"
            thermalEmoji = "🟠"
        case .critical:
            thermalState = "Critical"
            thermalEmoji = "🔴"
        @unknown default:
            thermalState = "Unknown"
            thermalEmoji = "⚪"
        }
    }

    func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            usedMemoryMB = Double(info.resident_size) / 1_048_576
        }
    }

    func runAllBenchmarks() async {
        isRunning = true
        updateThermalState()

        let memBefore = currentMemoryMB()
        await runVisionClassificationBenchmark()
        benchmarks[0].memoryDeltaMB = currentMemoryMB() - memBefore

        let mem2 = currentMemoryMB()
        await runVisionOCRBenchmark()
        benchmarks[1].memoryDeltaMB = currentMemoryMB() - mem2

        let mem3 = currentMemoryMB()
        await runSentimentBenchmark()
        benchmarks[2].memoryDeltaMB = currentMemoryMB() - mem3

        let mem4 = currentMemoryMB()
        await runEmbeddingBenchmark()
        benchmarks[3].memoryDeltaMB = currentMemoryMB() - mem4

        updateThermalState()
        updateMemoryUsage()
        isRunning = false
    }

    private func runVisionClassificationBenchmark() async {
        let idx = 0
        benchmarks[idx].status = "Running..."
        let image = TestImageFactory.syntheticScene()
        guard let cgImage = image.cgImage else {
            benchmarks[idx].status = "FAIL"
            return
        }

        let start = CFAbsoluteTimeGetCurrent()
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            benchmarks[idx].status = "FAIL"
            benchmarks[idx].details = error.localizedDescription
            return
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        benchmarks[idx].latencyMs = elapsed
        benchmarks[idx].details = "\(request.results?.count ?? 0) labels"
        benchmarks[idx].status = "DONE"
    }

    private func runVisionOCRBenchmark() async {
        let idx = 1
        benchmarks[idx].status = "Running..."
        let image = TestImageFactory.textImage("Benchmark OCR Test String 12345")
        guard let cgImage = image.cgImage else {
            benchmarks[idx].status = "FAIL"
            return
        }

        let start = CFAbsoluteTimeGetCurrent()
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            benchmarks[idx].status = "FAIL"
            return
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        benchmarks[idx].latencyMs = elapsed
        let texts = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        benchmarks[idx].details = "Recognized: \(texts.joined(separator: " "))"
        benchmarks[idx].status = "DONE"
    }

    private func runSentimentBenchmark() async {
        let idx = 2
        benchmarks[idx].status = "Running..."

        let texts = (0..<100).map { i in
            i % 2 == 0
                ? "This product is excellent and amazing."
                : "This is terrible and disappointing."
        }

        let start = CFAbsoluteTimeGetCurrent()
        var positiveCount = 0
        var negativeCount = 0

        for text in texts {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = text
            if let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0 {
                let score = Double(tag.rawValue) ?? 0
                if score > 0 { positiveCount += 1 }
                else if score < 0 { negativeCount += 1 }
            }
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        benchmarks[idx].latencyMs = elapsed
        benchmarks[idx].details = "100 texts in \(String(format: "%.1f", elapsed))ms (\(String(format: "%.2f", elapsed / 100))ms/text)\nPositive: \(positiveCount), Negative: \(negativeCount)"
        benchmarks[idx].status = "DONE"
    }

    private func runEmbeddingBenchmark() async {
        let idx = 3
        benchmarks[idx].status = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        if let embedding = NLEmbedding.wordEmbedding(for: .english) {
            let words = ["computer", "science", "machine", "learning", "neural", "network", "data", "model", "train", "test"]
            var foundCount = 0
            for word in words {
                let neighbors = embedding.neighbors(for: word, maximumCount: 3)
                if !neighbors.isEmpty { foundCount += 1 }
            }
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            benchmarks[idx].latencyMs = elapsed
            benchmarks[idx].details = "\(foundCount)/\(words.count) words found, \(String(format: "%.2f", elapsed / Double(words.count)))ms/lookup"
            benchmarks[idx].status = "DONE"
        } else {
            benchmarks[idx].status = "FAIL"
            benchmarks[idx].details = "Word embeddings unavailable"
        }
    }

    func scanModels() {
        discoveredModels = []
        let bundle = Bundle.main
        let extensions = ["mlmodelc", "mlpackage"]

        for ext in extensions {
            if let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    let start = CFAbsoluteTimeGetCurrent()
                    do {
                        let config = MLModelConfiguration()
                        let model = try MLModel(contentsOf: url, configuration: config)
                        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                        let desc = model.modelDescription
                        let inputNames = desc.inputDescriptionsByName.keys.joined(separator: ", ")
                        let outputNames = desc.outputDescriptionsByName.keys.joined(separator: ", ")
                        discoveredModels.append((
                            url.lastPathComponent,
                            "Load: \(String(format: "%.1f", elapsed))ms | In: \(inputNames) | Out: \(outputNames)"
                        ))
                    } catch {
                        discoveredModels.append((url.lastPathComponent, "Failed: \(error.localizedDescription)"))
                    }
                }
            }
        }

        if discoveredModels.isEmpty {
            discoveredModels.append(("No models found", "Add .mlmodelc or .mlpackage files to the bundle"))
        }
    }

    func runStressTest() async {
        isStressTesting = true
        stressStats = nil
        let iterations = Int(stressIterations)
        let image = TestImageFactory.syntheticScene()
        guard let cgImage = image.cgImage else {
            isStressTesting = false
            return
        }

        var latencies: [Double] = []
        latencies.reserveCapacity(iterations)

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            latencies.append(elapsed)
        }

        let sorted = latencies.sorted()
        let sum = sorted.reduce(0, +)
        let mean = sum / Double(sorted.count)
        let median = sorted.count % 2 == 0
            ? (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
            : sorted[sorted.count / 2]
        let p95Index = Int(Double(sorted.count) * 0.95)
        let p99Index = Int(Double(sorted.count) * 0.99)
        let variance = sorted.map { pow($0 - mean, 2) }.reduce(0, +) / Double(sorted.count)
        let stddev = sqrt(variance)

        stressStats = StressTestStats(
            mean: mean,
            median: median,
            p95: sorted[min(p95Index, sorted.count - 1)],
            p99: sorted[min(p99Index, sorted.count - 1)],
            stddev: stddev,
            min: sorted.first ?? 0,
            max: sorted.last ?? 0,
            count: iterations
        )
        isStressTesting = false
    }

    private func currentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : 0
    }

    private func deviceModelName() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

struct CoreMLBenchmarkView: View {
    @State private var vm = CoreMLBenchmarkViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Device Info") {
                    LabeledContent("Model", value: vm.deviceModel)
                        .accessibilityIdentifier("benchmark_device_model")
                    LabeledContent("OS", value: vm.osVersion)
                        .accessibilityIdentifier("benchmark_os_version")
                    LabeledContent("Thermal") {
                        Text("\(vm.thermalEmoji) \(vm.thermalState)")
                    }
                    .accessibilityIdentifier("benchmark_thermal")
                    LabeledContent("Processors", value: "\(vm.processorCount)")
                        .accessibilityIdentifier("benchmark_processors")
                    LabeledContent("Physical Memory", value: String(format: "%.1f GB", vm.physicalMemoryGB))
                        .accessibilityIdentifier("benchmark_memory")
                    LabeledContent("Used Memory", value: String(format: "%.1f MB", vm.usedMemoryMB))
                        .accessibilityIdentifier("benchmark_used_memory")
                }

                Section {
                    Button(vm.isRunning ? "Running..." : "Run Full Benchmark Suite") {
                        Task { await vm.runAllBenchmarks() }
                    }
                    .disabled(vm.isRunning)
                    .accessibilityIdentifier("benchmark_run_all")
                } header: {
                    Text("Framework Benchmarks")
                }

                Section("Benchmark Results") {
                    ForEach(vm.benchmarks) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(result.name).font(.headline)
                                Spacer()
                                Text(result.status)
                                    .font(.caption)
                                    .foregroundStyle(result.status == "DONE" ? .green : result.status == "FAIL" ? .red : .secondary)
                                    .accessibilityIdentifier("benchmark_status_\(result.name)")
                            }
                            if result.latencyMs > 0 {
                                HStack {
                                    Text("\(String(format: "%.1f", result.latencyMs)) ms")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if result.memoryDeltaMB != 0 {
                                        Text("Δ \(String(format: "%.1f", result.memoryDeltaMB)) MB")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            if !result.details.isEmpty {
                                Text(result.details)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Custom Model Scanner") {
                    Button("Scan Bundle for Models") {
                        vm.scanModels()
                    }
                    .accessibilityIdentifier("benchmark_scan_models")

                    ForEach(vm.discoveredModels, id: \.0) { name, info in
                        VStack(alignment: .leading) {
                            Text(name).font(.caption).fontWeight(.medium)
                            Text(info).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Stress Test") {
                    VStack(alignment: .leading) {
                        Text("Iterations: \(Int(vm.stressIterations))")
                        Slider(value: $vm.stressIterations, in: 10...1000, step: 10)
                            .accessibilityIdentifier("benchmark_stress_slider")
                    }

                    Button(vm.isStressTesting ? "Running Stress Test..." : "Run Stress Test") {
                        Task { await vm.runStressTest() }
                    }
                    .disabled(vm.isStressTesting)
                    .accessibilityIdentifier("benchmark_run_stress")

                    if let stats = vm.stressStats {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Results (\(stats.count) iterations)").font(.headline)
                            LabeledContent("Mean", value: String(format: "%.2f ms", stats.mean))
                            LabeledContent("Median", value: String(format: "%.2f ms", stats.median))
                            LabeledContent("P95", value: String(format: "%.2f ms", stats.p95))
                            LabeledContent("P99", value: String(format: "%.2f ms", stats.p99))
                            LabeledContent("Std Dev", value: String(format: "%.2f ms", stats.stddev))
                            LabeledContent("Min", value: String(format: "%.2f ms", stats.min))
                            LabeledContent("Max", value: String(format: "%.2f ms", stats.max))
                        }
                        .font(.caption)
                        .accessibilityIdentifier("benchmark_stress_results")
                    }
                }
            }
            .navigationTitle("CoreML Benchmark")
            .onAppear { vm.loadDeviceInfo() }
        }
    }
}
