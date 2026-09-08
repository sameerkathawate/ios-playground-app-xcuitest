// Demonstrates: AppIntents framework, Siri integration, Shortcuts — Apple ML QA
import SwiftUI

struct IntentInfo: Identifiable {
    let id = UUID()
    let name: String
    let triggerPhrase: String
    let description: String
    var lastResult: String = ""
    var latencyMs: Double = 0
}

@MainActor
@Observable
final class SiriIntentsViewModel {
    var intents: [IntentInfo] = [
        IntentInfo(
            name: "ClassifyImageIntent",
            triggerPhrase: "\"Classify an image with MLQATestApp\"",
            description: "Classifies a synthetic image using Vision framework, returns top labels"
        ),
        IntentInfo(
            name: "AnalyzeSentimentIntent",
            triggerPhrase: "\"Analyze sentiment with MLQATestApp\"",
            description: "Accepts text input, returns sentiment label and score"
        ),
        IntentInfo(
            name: "RunBenchmarkIntent",
            triggerPhrase: "\"Run ML benchmark with MLQATestApp\"",
            description: "Runs Vision + NLP benchmarks, returns latency and thermal state"
        ),
        IntentInfo(
            name: "ExtractTextIntent",
            triggerPhrase: "\"Extract text with MLQATestApp\"",
            description: "Performs OCR on a synthetic text image"
        ),
        IntentInfo(
            name: "CheckImageQualityIntent",
            triggerPhrase: "\"Check image quality with MLQATestApp\"",
            description: "Placeholder quality assessment of a synthetic image pair"
        )
    ]
    var isRunning = false

    func testClassifyIntent() async {
        let idx = 0
        intents[idx].lastResult = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        let intent = ClassifyImageIntent()
        do {
            let result = try await intent.perform()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            intents[idx].latencyMs = elapsed
            intents[idx].lastResult = result.value ?? "No result"
        } catch {
            intents[idx].lastResult = "Error: \(error.localizedDescription)"
        }
    }

    func testSentimentIntent() async {
        let idx = 1
        intents[idx].lastResult = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        let intent = AnalyzeSentimentIntent()
        intent.text = "I absolutely love this amazing product!"
        do {
            let result = try await intent.perform()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            intents[idx].latencyMs = elapsed
            intents[idx].lastResult = result.value ?? "No result"
        } catch {
            intents[idx].lastResult = "Error: \(error.localizedDescription)"
        }
    }

    func testBenchmarkIntent() async {
        let idx = 2
        intents[idx].lastResult = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        let intent = RunBenchmarkIntent()
        do {
            let result = try await intent.perform()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            intents[idx].latencyMs = elapsed
            intents[idx].lastResult = result.value ?? "No result"
        } catch {
            intents[idx].lastResult = "Error: \(error.localizedDescription)"
        }
    }

    func testExtractTextIntent() async {
        let idx = 3
        intents[idx].lastResult = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        let intent = ExtractTextIntent()
        do {
            let result = try await intent.perform()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            intents[idx].latencyMs = elapsed
            intents[idx].lastResult = result.value ?? "No result"
        } catch {
            intents[idx].lastResult = "Error: \(error.localizedDescription)"
        }
    }

    func testImageQualityIntent() async {
        let idx = 4
        intents[idx].lastResult = "Running..."

        let start = CFAbsoluteTimeGetCurrent()
        let intent = CheckImageQualityIntent()
        do {
            let result = try await intent.perform()
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            intents[idx].latencyMs = elapsed
            intents[idx].lastResult = result.value ?? "No result"
        } catch {
            intents[idx].lastResult = "Error: \(error.localizedDescription)"
        }
    }

    func testIntent(at index: Int) async {
        isRunning = true
        switch index {
        case 0: await testClassifyIntent()
        case 1: await testSentimentIntent()
        case 2: await testBenchmarkIntent()
        case 3: await testExtractTextIntent()
        case 4: await testImageQualityIntent()
        default: break
        }
        isRunning = false
    }
}

struct SiriIntentsView: View {
    @State private var vm = SiriIntentsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("These App Intents expose ML features to Siri and the Shortcuts app. Each intent can be tested locally below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(vm.intents.enumerated()), id: \.element.id) { index, intent in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(intent.name)
                                .font(.headline)
                                .accessibilityIdentifier("siri_intent_\(intent.name)")

                            Text(intent.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundStyle(.blue)
                                Text(intent.triggerPhrase)
                                    .font(.caption)
                                    .italic()
                            }

                            Button("Test Intent") {
                                Task { await vm.testIntent(at: index) }
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isRunning)
                            .accessibilityIdentifier("siri_test_\(intent.name)")

                            if !intent.lastResult.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    if intent.latencyMs > 0 {
                                        Text("\(String(format: "%.1f", intent.latencyMs)) ms")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(intent.lastResult)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(5)
                                        .accessibilityIdentifier("siri_result_\(intent.name)")
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Siri & App Intents")
        }
    }
}
