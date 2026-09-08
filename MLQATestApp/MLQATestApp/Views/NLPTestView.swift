// Demonstrates: NaturalLanguage framework, sentiment analysis, NER, tokenization, embeddings — Apple ML QA
import SwiftUI
import NaturalLanguage

struct NLPTestResult: Identifiable {
    let id = UUID()
    let name: String
    var status: String = "Idle"
    var details: String = ""
    var latencyMs: Double = 0
}

@MainActor
@Observable
final class NLPTestViewModel {
    var inputText: String = "Apple Inc. was founded by Steve Jobs in Cupertino, California. The company creates amazing products that people love. Their innovative technology has changed the world."
    var comparisonText: String = "Technology companies drive innovation in Silicon Valley."
    var results: [NLPTestResult] = [
        NLPTestResult(name: "Language Detection"),
        NLPTestResult(name: "Sentiment Analysis"),
        NLPTestResult(name: "Named Entity Recognition"),
        NLPTestResult(name: "Tokenization"),
        NLPTestResult(name: "Embedding Similarity")
    ]
    var isRunning = false

    let sampleTexts: [(String, String)] = [
        ("Positive", "I absolutely love this product! It's fantastic and works perfectly. The quality is outstanding and the design is beautiful."),
        ("Negative", "This is terrible. The worst experience I've ever had. Nothing works properly and the support is awful. Very disappointed."),
        ("Multi-language", "Hello World. Bonjour le monde. Hola mundo. こんにちは世界。Hallo Welt."),
        ("Technical", "The convolutional neural network achieved 97.3% accuracy on the CIFAR-10 dataset using batch normalization and dropout regularization.")
    ]

    func useSample(_ text: String) {
        inputText = text
    }

    func runAllTests() async {
        isRunning = true
        for i in results.indices {
            results[i].status = "Running..."
            results[i].details = ""
        }
        await runLanguageDetection()
        await runSentimentAnalysis()
        await runNER()
        await runTokenization()
        await runEmbeddingSimilarity()
        isRunning = false
    }

    func runLanguageDetection() async {
        let idx = 0
        let start = CFAbsoluteTimeGetCurrent()

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(inputText)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        results[idx].latencyMs = elapsed

        if hypotheses.isEmpty {
            results[idx].status = "FAIL"
            results[idx].details = "No language detected"
        } else {
            let sorted = hypotheses.sorted { $0.value > $1.value }
            results[idx].details = sorted.map { lang, prob in
                "\(lang.rawValue): \(String(format: "%.1f%%", prob * 100))"
            }.joined(separator: "\n")
            results[idx].status = "PASS"
        }
    }

    func runSentimentAnalysis() async {
        let idx = 1
        let start = CFAbsoluteTimeGetCurrent()

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = inputText

        var sentenceScores: [(String, Double)] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = inputText

        tokenizer.enumerateTokens(in: inputText.startIndex..<inputText.endIndex) { range, _ in
            let sentence = String(inputText[range])
            let sentenceTagger = NLTagger(tagSchemes: [.sentimentScore])
            sentenceTagger.string = sentence
            if let tag = sentenceTagger.tag(at: sentence.startIndex, unit: .paragraph, scheme: .sentimentScore).0 {
                let score = Double(tag.rawValue) ?? 0
                sentenceScores.append((sentence.trimmingCharacters(in: .whitespacesAndNewlines), score))
            }
            return true
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        results[idx].latencyMs = elapsed

        let overallTag = tagger.tag(at: inputText.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        let overallScore = Double(overallTag?.rawValue ?? "0") ?? 0

        var details = "Overall: \(String(format: "%.3f", overallScore)) (\(sentimentLabel(overallScore)))"
        for (sentence, score) in sentenceScores.prefix(5) {
            let truncated = sentence.count > 40 ? String(sentence.prefix(40)) + "..." : sentence
            details += "\n  \"\(truncated)\" → \(String(format: "%.3f", score))"
        }
        results[idx].details = details
        results[idx].status = "PASS"
    }

    func runNER() async {
        let idx = 2
        let start = CFAbsoluteTimeGetCurrent()

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = inputText
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]

        var entities: [(String, String)] = []
        tagger.enumerateTags(in: inputText.startIndex..<inputText.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag {
                let entity = String(inputText[range])
                let type: String
                switch tag {
                case .personalName: type = "Person"
                case .placeName: type = "Place"
                case .organizationName: type = "Organization"
                default: type = tag.rawValue
                }
                entities.append((entity, type))
            }
            return true
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        results[idx].latencyMs = elapsed

        if entities.isEmpty {
            results[idx].details = "No named entities detected"
            results[idx].status = "FAIL"
        } else {
            results[idx].details = entities.map { "\($0.0) [\($0.1)]" }.joined(separator: "\n")
            results[idx].status = "PASS"
        }
    }

    func runTokenization() async {
        let idx = 3
        let start = CFAbsoluteTimeGetCurrent()

        let wordTokenizer = NLTokenizer(unit: .word)
        wordTokenizer.string = inputText
        var wordCount = 0
        wordTokenizer.enumerateTokens(in: inputText.startIndex..<inputText.endIndex) { _, _ in
            wordCount += 1
            return true
        }

        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.string = inputText
        var sentenceCount = 0
        sentenceTokenizer.enumerateTokens(in: inputText.startIndex..<inputText.endIndex) { _, _ in
            sentenceCount += 1
            return true
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        results[idx].latencyMs = elapsed
        results[idx].details = "Words: \(wordCount)\nSentences: \(sentenceCount)\nAvg words/sentence: \(String(format: "%.1f", sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0))"
        results[idx].status = "PASS"
    }

    func runEmbeddingSimilarity() async {
        let idx = 4
        let start = CFAbsoluteTimeGetCurrent()

        var details = ""

        if let wordEmbedding = NLEmbedding.wordEmbedding(for: .english) {
            let word = "technology"
            let neighbors = wordEmbedding.neighbors(for: word, maximumCount: 5)
            details += "Nearest neighbors for \"\(word)\":\n"
            details += neighbors.map { "\($0.0) (dist: \(String(format: "%.3f", $0.1)))" }.joined(separator: "\n")
        } else {
            details += "Word embeddings unavailable"
        }

        if let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) {
            let distance = sentenceEmbedding.distance(between: inputText, and: comparisonText)
            details += "\n\nSentence similarity:"
            details += "\nDistance: \(String(format: "%.3f", distance))"
            let similarity = max(0, 1 - distance / 2)
            details += "\nCosine similarity: \(String(format: "%.3f", similarity))"
        } else {
            details += "\n\nSentence embeddings unavailable"
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        results[idx].latencyMs = elapsed
        results[idx].details = details
        results[idx].status = "PASS"
    }

    private func sentimentLabel(_ score: Double) -> String {
        if score > 0.1 { return "Positive" }
        if score < -0.1 { return "Negative" }
        return "Neutral"
    }
}

struct NLPTestView: View {
    @State private var vm = NLPTestViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Input Text") {
                    TextEditor(text: $vm.inputText)
                        .frame(minHeight: 80)
                        .accessibilityIdentifier("nlp_input_text")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(vm.sampleTexts, id: \.0) { name, text in
                                Button(name) {
                                    vm.useSample(text)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("nlp_sample_\(name)")
                            }
                        }
                    }
                }

                Section("Comparison Text (for embeddings)") {
                    TextField("Comparison text", text: $vm.comparisonText)
                        .accessibilityIdentifier("nlp_comparison_text")
                }

                Section {
                    Button(vm.isRunning ? "Running..." : "Run All NLP Tests") {
                        Task { await vm.runAllTests() }
                    }
                    .disabled(vm.inputText.isEmpty || vm.isRunning)
                    .accessibilityIdentifier("nlp_run_all")
                }

                Section("Results") {
                    ForEach(vm.results) { result in
                        NLPResultRow(result: result)
                    }
                }
            }
            .navigationTitle("NLP Tests")
        }
    }
}

struct NLPResultRow: View {
    let result: NLPTestResult

    var statusColor: Color {
        switch result.status {
        case "PASS": return .green
        case "FAIL": return .red
        case "Running...": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.name)
                    .font(.headline)
                Spacer()
                Text(result.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .accessibilityIdentifier("nlp_status_\(result.name)")
            }

            if result.latencyMs > 0 {
                Text("\(String(format: "%.1f", result.latencyMs)) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !result.details.isEmpty && result.status != "Idle" {
                Text(result.details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(10)
                    .accessibilityIdentifier("nlp_details_\(result.name)")
            }
        }
        .padding(.vertical, 4)
    }
}
