//
//  README.md
//  XCUITestPlaygroundApp
//
# XCUITestPlayground

A SwiftUI test sandbox designed to validate XCUITest interaction patterns:
- SwiftUI controls (Toggle, Slider, Picker, etc.)
- Material / "glass" UI hit-testing
- Gestures (drag, long-press)
- Async loading and flake-resistant waits
- Performance scrolling stress

## Run
- Open in Xcode
- Run `XCUITestPlaygroundUITests`

## Key Principles
- Accessibility identifiers for all interactive elements
- Deterministic async simulation
- Separate screens per XCUITest capability area
