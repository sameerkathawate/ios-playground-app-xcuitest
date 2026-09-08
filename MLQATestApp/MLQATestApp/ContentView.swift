import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VisionTestView()
                .tabItem { Label("Vision", systemImage: "eye") }
                .accessibilityIdentifier("tab_vision")

            NLPTestView()
                .tabItem { Label("NLP", systemImage: "text.bubble") }
                .accessibilityIdentifier("tab_nlp")

            CoreMLBenchmarkView()
                .tabItem { Label("Benchmark", systemImage: "speedometer") }
                .accessibilityIdentifier("tab_benchmark")

            ImageQualityView()
                .tabItem { Label("Image QA", systemImage: "photo.badge.checkmark") }
                .accessibilityIdentifier("tab_image_qa")

            SiriIntentsView()
                .tabItem { Label("Siri", systemImage: "mic") }
                .accessibilityIdentifier("tab_siri")
        }
    }
}
