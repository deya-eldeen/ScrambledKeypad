import SwiftUI
import ScrambledKeypad

@main
struct ScambledKeypadExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var entered: [Int] = []
    @State private var scrambleSeed = 0
    @State private var isCorrect: Bool? = nil
    @State private var hapticsEnabled = true
    @State private var sizeVariationEnabled = true
    @State private var emptySpaceEnabled = true
    private let maxDigits = 4
    private let correctPin = [7, 3, 2, 9]

    var body: some View {
        let canSubmit = entered.count == maxDigits
        VStack(spacing: 24) {
            Text("Enter PIN")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("Demo password is 7329")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(
                            Circle().fill(index < entered.count ? Color.primary : Color.clear)
                        )
                        .frame(width: 16, height: 16)
                }
            }

            ScrambledKeypad(
                includeDelete: true,
                includeEnter: true,
                enableHaptics: hapticsEnabled,
                enableSizeVariation: sizeVariationEnabled,
                enableEmptySpaceButton: emptySpaceEnabled,
                scrambleTrigger: scrambleSeed,
                onKeyPress: { digit in
                    guard entered.count < maxDigits else { return }
                    entered.append(digit)
                    isCorrect = nil
                },
                onDelete: {
                    _ = entered.popLast()
                    isCorrect = nil
                },
                onEnter: canSubmit ? submit : nil
            )
            .padding(.vertical, 12)

            if let isCorrect {
                Text(isCorrect ? "Correct" : "Incorrect")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isCorrect ? Color.green : Color.red)
            }

            Spacer(minLength: 32)

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Variable key sizes", isOn: $sizeVariationEnabled)
                    Toggle("Empty space buttons", isOn: $emptySpaceEnabled)
                        .disabled(!sizeVariationEnabled)
                }
                .toggleStyle(.switch)

                HStack(spacing: 12) {
                    Button("Scramble") {
                        scrambleSeed += 1
                        entered.removeAll()
                        isCorrect = nil
                    }
                    .buttonStyle(.bordered)

                    Button("Clear") {
                        entered.removeAll()
                        isCorrect = nil
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
    }

    private func submit() {
        isCorrect = entered == correctPin
    }
}
