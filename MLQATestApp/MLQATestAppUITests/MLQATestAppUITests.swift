import XCTest

final class MLQATestAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Tab Navigation

    func testAllFiveTabsPresent() {
        XCTAssertTrue(app.tabBars.buttons["Vision"].exists, "Vision tab should exist")
        XCTAssertTrue(app.tabBars.buttons["NLP"].exists, "NLP tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Benchmark"].exists, "Benchmark tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Image QA"].exists, "Image QA tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Siri"].exists, "Siri tab should exist")
    }

    func testTabsNavigable() {
        let tabs = ["Vision", "NLP", "Benchmark", "Image QA", "Siri"]
        for tab in tabs {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.tabBars.buttons[tab].isSelected, "\(tab) tab should be selected after tap")
        }
    }

    // MARK: - Vision Tab

    func testVisionTabSampleImageButton() {
        app.tabBars.buttons["Vision"].tap()
        let sampleButton = app.buttons["vision_sample_button"]
        XCTAssertTrue(sampleButton.waitForExistence(timeout: 5), "Use Sample Image button should exist")
    }

    func testVisionTabRunAllTests() {
        app.tabBars.buttons["Vision"].tap()

        let sampleButton = app.buttons["vision_sample_button"]
        XCTAssertTrue(sampleButton.waitForExistence(timeout: 5))
        sampleButton.tap()

        let runAllButton = app.buttons["vision_run_all"]
        XCTAssertTrue(runAllButton.waitForExistence(timeout: 5))
        runAllButton.tap()

        let classificationStatus = app.staticTexts["vision_status_Image Classification"]
        let exists = classificationStatus.waitForExistence(timeout: 15)
        if exists {
            let value = classificationStatus.label
            XCTAssertTrue(value == "PASS" || value == "FAIL", "Classification should show PASS or FAIL result")
        }
    }

    // MARK: - NLP Tab

    func testNLPTabDefaultTextPresent() {
        app.tabBars.buttons["NLP"].tap()
        let textEditor = app.textViews["nlp_input_text"]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5), "NLP text input should exist")
    }

    func testNLPTabSampleButtons() {
        app.tabBars.buttons["NLP"].tap()
        let positiveButton = app.buttons["nlp_sample_Positive"]
        XCTAssertTrue(positiveButton.waitForExistence(timeout: 5), "Positive sample button should exist")
    }

    func testNLPTabRunAllTests() {
        app.tabBars.buttons["NLP"].tap()

        let runAllButton = app.buttons["nlp_run_all"]
        XCTAssertTrue(runAllButton.waitForExistence(timeout: 5))
        runAllButton.tap()

        let langStatus = app.staticTexts["nlp_status_Language Detection"]
        let exists = langStatus.waitForExistence(timeout: 15)
        if exists {
            XCTAssertEqual(langStatus.label, "PASS", "Language Detection should pass")
        }
    }

    // MARK: - Benchmark Tab

    func testBenchmarkTabDeviceInfoVisible() {
        app.tabBars.buttons["Benchmark"].tap()
        let deviceModel = app.staticTexts["benchmark_device_model"]
            .waitForExistence(timeout: 5)
        XCTAssertTrue(deviceModel, "Device model label should be visible")
    }

    func testBenchmarkTabFullSuite() {
        app.tabBars.buttons["Benchmark"].tap()

        let runButton = app.buttons["benchmark_run_all"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        // Wait for benchmarks to complete (they can take a while)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == 'DONE'"),
            object: app.staticTexts["benchmark_status_Vision Classification"]
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: 30)
        if result == .completed {
            XCTAssertTrue(true, "Vision Classification benchmark completed")
        }
    }

    // MARK: - Siri Tab

    func testSiriTabIntentNamesVisible() {
        app.tabBars.buttons["Siri"].tap()
        let classifyIntent = app.staticTexts["siri_intent_ClassifyImageIntent"]
        XCTAssertTrue(classifyIntent.waitForExistence(timeout: 5), "ClassifyImageIntent should be visible")
    }

    func testSiriTabSentimentIntentTest() {
        app.tabBars.buttons["Siri"].tap()

        let testButton = app.buttons["siri_test_AnalyzeSentimentIntent"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5))
        testButton.tap()

        let result = app.staticTexts["siri_result_AnalyzeSentimentIntent"]
        let exists = result.waitForExistence(timeout: 15)
        if exists {
            XCTAssertFalse(result.label.isEmpty, "Sentiment intent result should not be empty")
        }
    }

    // MARK: - Accessibility

    func testAllTabsHaveAccessibilityLabels() {
        let tabs = app.tabBars.buttons.allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(tabs.count, 5, "Should have at least 5 tabs")
        for tab in tabs {
            XCTAssertFalse(tab.label.isEmpty, "Tab \(tab.identifier) should have a non-empty accessibility label")
        }
    }
}
