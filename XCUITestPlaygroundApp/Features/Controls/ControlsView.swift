import SwiftUI

struct ControlsView: View {

    @State private var textValue = ""
    @State private var passwordValue = ""
    @State private var adjustableValue: Double = 5
    @State private var pickerSelection: SegmentOption = .a
    @State private var date = Date()
    @State private var isDisabled = true
    @State private var showPassword = false

    enum SegmentOption: String, CaseIterable, Identifiable {
        case a = "Option A"
        case b = "Option B"
        case c = "Option C"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Text Inputs
                Section("Text") {
                    VStack(alignment: .leading, spacing: 12) {

                        TextField("Enter text", text: $textValue)
                            .accessibilityIdentifier("controls_textfield")

                        HStack {

                            if showPassword {
                                TextField("Enter password", text: $passwordValue)
                                    .accessibilityIdentifier("controls_password_textfield")
                                    .textFieldStyle(.automatic)
                            } else {
                                SecureField("Enter password", text: $passwordValue)
                                    .accessibilityIdentifier("controls_securefield")
                                    .textFieldStyle(.automatic)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .accessibilityIdentifier("controls_show_password")
                        }
                    }
                }

                // MARK: Adjustables
                Section("Adjustables") {
                    VStack(spacing: 12) {

                        Slider(value: $adjustableValue, in: 0...10, step: 1)
                            .accessibilityIdentifier("controls_slider")

                        HStack {
                            Text("Value")

                            Spacer()

                            Stepper("\(Int(adjustableValue))",
                                    value: $adjustableValue,
                                    in: 0...10,
                                    step: 1)
                            .accessibilityIdentifier("controls_stepper")
                        }
                    }
                }

                // MARK: Pickers
                Section("Pickers") {
                    VStack(spacing: 12) {

                        Picker("Segment", selection: $pickerSelection) {
                            ForEach(SegmentOption.allCases) { option in
                                Text(option.rawValue)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("controls_segmented")

                        HStack {
                            Text("Selected")
                            Spacer()
                            Text(pickerSelection.rawValue)
                                .accessibilityIdentifier("controls_picker_value")
                        }

                        DatePicker("Date",
                                   selection: $date,
                                   displayedComponents: .date)
                        .accessibilityIdentifier("controls_datepicker")
                    }
                }

                // MARK: Buttons
                Section("Buttons") {
                    VStack(spacing: 12) {

                        HStack {
                            Button("Primary Button") {}
                                .accessibilityIdentifier("controls_primary_button")

                            Spacer()

                            Button("Disabled Button") {}
                                .disabled(isDisabled)
                                .accessibilityIdentifier("controls_disabled_button")
                        }

                        Toggle("Disable Above Button", isOn: $isDisabled)
                            .accessibilityIdentifier("controls_disable_toggle")
                    }
                }

                // MARK: ZStack Overlay Example
                Section("Overlay Layout") {
                    ZStack {

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.05))
                            .frame(height: 80)
                            .accessibilityIdentifier("zstack_background")

                        HStack {
                            Text("Overlay Text")
                                .accessibilityIdentifier("zstack_text")

                            Spacer()

                            Button("Action") {}
                                .accessibilityIdentifier("zstack_button")
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Controls")
        }
    }
}
