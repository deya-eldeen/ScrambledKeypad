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
    private let maxDigits = 4

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter PIN")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

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
                onKeyPress: { digit in
                    guard entered.count < maxDigits else { return }
                    entered.append(digit)
                },
                onDelete: {
                    _ = entered.popLast()
                }
            )

            Button("Clear") {
                entered.removeAll()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }
}
