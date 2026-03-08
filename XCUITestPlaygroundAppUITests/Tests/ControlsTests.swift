//
//  ControlsTests.swift
//  XCUITestPlaygroundApp
//
import XCTest

class ControlsTests: XCTestCase {
    
    func test_textbox_can_be_filled() {
        let app = XCUIApplication()
        app.launch()
        
        let textField = app.textFields["controls_textfield"]
        textField.tap()
        textField.typeText("Hello, World!")
        XCTAssertEqual(textField.value as? String, "Hello, World!")
        
        let passwordField = app.secureTextFields["controls_securefield"]
        passwordField.tap()
        passwordField.typeText("secretPassword")
        XCTAssert(passwordField.exists)
    }
    
    func test_password_visibility_can_be_toggled() {
        let app = XCUIApplication()
        app.launch()
        
        let passwordField = app.secureTextFields["controls_securefield"]
        XCTAssert(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("password")
        XCTAssertNotEqual(passwordField.value as? String, "password")
        
        let toggleEyeButton = app.buttons["controls_show_password"]
        toggleEyeButton.tap()
        
        let visibleField = app.textFields["controls_password_textfield"]
        XCTAssertEqual(visibleField.value as? String, "password")
    }
    
    func test_slider_changes_value() {
        let app = XCUIApplication()
        app.launch()
        
        let slider = app.sliders["controls_slider"]
        slider.adjust(toNormalizedSliderPosition: 0.75) //moves approximately not exactly - thats why i ddint set it to 0.8
        
        let stepper = app.steppers["controls_stepper"]
        XCTAssert(stepper.exists)
        XCTAssertTrue(stepper.label.contains("8"))
        
    }
    
    func test_pickers() {
        let app = XCUIApplication()
        app.launch()
        
        let selectedPicker = app.staticTexts["controls_picker_value"]
        XCTAssertEqual(selectedPicker.label, "Option A")
        
        let optionB = app.buttons["Option B"]
        let optionC = app.buttons["Option C"]
        
        optionB.tap()
        XCTAssertEqual(selectedPicker.label, "Option B")
        
        optionC.tap()
        XCTAssertEqual(selectedPicker.label, "Option C")
        
        let segmented = app.segmentedControls["controls_segmented"]
        XCTAssertTrue(segmented.exists)
    }
}
