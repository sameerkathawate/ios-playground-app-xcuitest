# MLQATestApp — On-Device ML & Siri Test Harness for iOS

A SwiftUI iOS test harness that validates on-device ML capabilities across Apple's frameworks. Built as a portfolio piece demonstrating ML QA skills for Apple's Machine Learning Engineer, Software QA role.

## Job Requirement Mapping

| Requirement | Module | Implementation |
|---|---|---|
| ML, deep learning, computer vision | Vision Tests | VNClassifyImageRequest, object detection, face landmarks, saliency |
| NLP and generative AI | NLP Tests | NLTagger sentiment, NLLanguageRecognizer, NER, embeddings |
| Data preparation & quality evaluation | Image Quality | PSNR, noise estimation, sharpness, histogram analysis, color science |
| Swift proficiency | All modules | Swift concurrency (async/await), @Observable, MVVM architecture |
| iOS/macOS familiarity | All modules | Vision, NaturalLanguage, CoreML, CoreImage, AppIntents frameworks |
| SQA methodologies | Tests | 30+ XCTest unit tests, XCUITest suite, performance benchmarks |
| Image/video quality, color science | Image Quality | PSNR, difference maps, histogram, noise sigma, white balance detection |
| Prototyping and tools development | Benchmark | Stress testing, device profiling, model scanning, latency statistics |
| Siri / App Intents | Siri Tab | 5 AppIntents, AppShortcutsProvider, Shortcuts integration |

## Architecture

```
MVVM with @Observable ViewModels
├── Views        → Declarative SwiftUI (presentation only)
├── ViewModels   → @MainActor @Observable (business logic, embedded in view files)
├── Intents      → AppIntents for Siri/Shortcuts integration
└── Utilities    → TestImageFactory (synthetic test image generation)
```

**Zero external dependencies** — uses only Apple frameworks: Vision, NaturalLanguage, CoreML, CoreImage, AppIntents.

## Modules

### Tab 1: Vision Tests
- Image Classification (VNClassifyImageRequest) — top-5 labels with confidence
- Rectangle Detection (VNDetectRectanglesRequest) — bounding boxes
- Text Recognition / OCR (VNRecognizeTextRequest) — accurate mode with language correction
- Face & Landmark Detection (VNDetectFaceLandmarksRequest) — landmark count, roll/yaw
- Attention Saliency (VNGenerateAttentionBasedSaliencyImageRequest) — salient region count
- Barcode Detection (VNDetectBarcodesRequest) — symbology and payload
- Each test tracks latency (ms) and displays pass/fail based on confidence thresholds

### Tab 2: NLP Tests
- Language Detection — NLLanguageRecognizer with top-5 probability distribution
- Sentiment Analysis — NLTagger sentimentScore at sentence granularity
- Named Entity Recognition — Person/Place/Organization extraction
- Tokenization — Word and sentence counts
- Embedding Similarity — Word neighbors + sentence cosine similarity
- Includes sample text presets (positive, negative, multi-language, technical)

### Tab 3: CoreML Benchmark
- Device profiling: model, OS, thermal state (emoji indicators), CPU count, memory usage
- Framework benchmarks: Vision classification, OCR, NLP sentiment throughput, embedding lookup
- Custom model scanner: discovers .mlmodelc/.mlpackage in bundle, reports load time and schema
- Stress test: configurable iterations (10–1000), computes mean/median/P95/P99/stddev/min/max

### Tab 4: Image Quality Evaluation
- PSNR (Peak Signal-to-Noise Ratio) with quality thresholds
- Difference Map visualization (CIFilter.differenceBlendMode)
- Histogram Analysis — per-channel RGB mean, std dev, dynamic range
- Noise Estimation — Laplacian-based noise sigma
- Sharpness — Laplacian variance for blur detection
- Color Space Stats — RGB averages, white balance, color cast detection
- Generate Reference Pair button creates clean + degraded test images

### Tab 5: Siri & App Intents
- ClassifyImageIntent — classifies synthetic image
- AnalyzeSentimentIntent — analyzes text sentiment with @Parameter
- RunBenchmarkIntent — Vision + NLP latency + thermal state
- ExtractTextIntent — OCR on synthetic text image
- CheckImageQualityIntent — PSNR quality assessment
- AppShortcutsProvider with Siri trigger phrases
- Local testing with latency tracking

## Test Suite

### Unit Tests (30+ tests)
- **Vision**: classification results, confidence thresholds, latency < 500ms, deterministic output, OCR text detection, blank image handling, rectangle detection
- **NLP**: English/Spanish language detection, positive/negative sentiment polarity, NER for person/org/place, tokenization word count, embedding availability, neighbor relevance
- **Image Quality**: PSNR infinite for identical images, PSNR range for degraded images, sharpness positive for non-blank, sharpness low for blank
- **App Intents**: each intent returns non-nil result, sentiment meaningful output, benchmark reports latency
- **Performance**: measure{} blocks for Vision classification and NLP sentiment throughput

### UI Tests (XCUITest)
- All 5 tabs present and navigable
- Vision: sample image button, run all tests produces results
- NLP: default text present, sample buttons, run all shows language results
- Benchmark: device info visible, full suite produces results
- Siri: intent names visible, sentiment intent shows result
- Accessibility: all tabs have non-empty accessibility labels

## Setup

1. Open `MLQATestApp.xcodeproj` in Xcode 15+ (or 16+)
2. Select an iOS 17+ simulator or device
3. Build and run (Cmd+R)
4. Run unit tests: Cmd+U
5. Run UI tests: select the MLQATestAppUITests scheme, Cmd+U

## File Structure

```
MLQATestApp/
├── MLQATestApp.xcodeproj/
├── MLQATestApp/
│   ├── MLQATestApp.swift          — App entry point
│   ├── ContentView.swift           — Tab-based navigation
│   ├── Views/
│   │   ├── VisionTestView.swift    — Vision framework tests + ViewModel
│   │   ├── NLPTestView.swift       — NaturalLanguage tests + ViewModel
│   │   ├── CoreMLBenchmarkView.swift — Performance benchmarks + ViewModel
│   │   ├── ImageQualityView.swift  — Image quality metrics + ViewModel
│   │   └── SiriIntentsView.swift   — App Intents test UI + ViewModel
│   ├── Intents/
│   │   └── MLAppIntents.swift      — 5 AppIntents + AppShortcutsProvider
│   └── Utilities/
│       └── TestImageFactory.swift  — Synthetic test image generation
├── MLQATestAppTests/
│   └── MLQATestAppTests.swift      — 30+ unit tests
└── MLQATestAppUITests/
    └── MLQATestAppUITests.swift    — UI automation tests
```

## Extension Guide

### Adding a New Vision Test
1. Add a new `VisionTestResult` entry to the `results` array in `VisionTestViewModel`
2. Create a `runNewTest(image:)` async method following the existing pattern
3. Call it from `runAllTests()`
4. Add corresponding unit test in `MLQATestAppTests`

### Adding a Custom CoreML Model
1. Drag a `.mlmodelc` or `.mlpackage` file into the Xcode project
2. The model scanner will auto-discover it and report input/output schema
3. Add benchmark code in `CoreMLBenchmarkViewModel` to exercise the model

### Adding a New App Intent
1. Create a new struct conforming to `AppIntent` in `MLAppIntents.swift`
2. Add an `AppShortcut` entry in `MLAppShortcuts`
3. Add the intent info to `SiriIntentsViewModel.intents`
4. Add a test method in `SiriIntentsViewModel` and wire it up in `testIntent(at:)`

### Adding a New Image Quality Metric
1. Add a `QualityMetric` entry to `ImageQualityViewModel.metrics`
2. Create a `computeNewMetric(image:)` method
3. Call it from `runAllMetrics()`
4. Add quality level thresholds and interpretation text
