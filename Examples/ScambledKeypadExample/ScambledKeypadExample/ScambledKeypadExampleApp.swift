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
    @State private var touchMarkers: [TouchMarker] = []
    @State private var showSmudges = true
    @State private var smudgeBlurRadius: Double = 0
    private let maxDigits = 4
    private let correctPin = [7, 3, 2, 9]

    var body: some View {
        let canSubmit = entered.count == maxDigits
        ZStack {
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
                        Toggle("Show smudges", isOn: $showSmudges)
                        VStack(spacing: 6) {
                            Text("Smudge blur: \(Int(smudgeBlurRadius))")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            Slider(value: $smudgeBlurRadius, in: 0...12, step: 1)
                        }
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
                            touchMarkers.removeAll()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(24)

            touchOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .coordinateSpace(name: "tapSpace")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("tapSpace"))
                .onChanged { value in
                    addTouch(at: value.location)
                }
        )
    }

    private func submit() {
        isCorrect = entered == correctPin
    }

    private var touchOverlay: some View {
        ZStack {
            ForEach(touchMarkers) { marker in
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 30, height: 30)
                    .position(marker.location)
                    .opacity(marker.opacity)
            }
        }
        .allowsHitTesting(false)
        .opacity(showSmudges ? 1 : 0)
        .blur(radius: smudgeBlurRadius)
    }

    private func addTouch(at location: CGPoint) {
        guard showSmudges else { return }
        let marker = TouchMarker(id: UUID(), location: location, opacity: 1)
        touchMarkers.append(marker)
    }
}

private struct TouchMarker: Identifiable {
    let id: UUID
    let location: CGPoint
    var opacity: Double
}
