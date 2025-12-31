import SwiftUI

public struct ScrambledKeypad: View {
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let includeDelete: Bool
    private let shuffleOnAppear: Bool
    private let onKeyPress: (Int) -> Void
    private let onDelete: (() -> Void)?

    @State private var digits: [Int] = ScrambledKeypadDigits.shuffled()

    public init(
        columns: Int = 3,
        spacing: CGFloat = 12,
        includeDelete: Bool = true,
        shuffleOnAppear: Bool = true,
        onKeyPress: @escaping (Int) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: max(1, columns))
        self.spacing = spacing
        self.includeDelete = includeDelete
        self.shuffleOnAppear = shuffleOnAppear
        self.onKeyPress = onKeyPress
        self.onDelete = onDelete
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(items) { item in
                switch item {
                case .digit(let value):
                    Button {
                        onKeyPress(value)
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(KeypadButtonStyle())
                case .delete:
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(KeypadButtonStyle())
                    .disabled(onDelete == nil)
                    .accessibilityLabel("Delete")
                }
            }
        }
        .onAppear {
            if shuffleOnAppear {
                digits = ScrambledKeypadDigits.shuffled()
            }
        }
    }

    private var items: [KeyItem] {
        var values = digits.map { KeyItem.digit($0) }
        if includeDelete {
            values.append(.delete)
        }
        return values
    }
}

private enum KeyItem: Hashable, Identifiable {
    case digit(Int)
    case delete

    var id: String {
        switch self {
        case .digit(let value):
            return "digit-\(value)"
        case .delete:
            return "delete"
        }
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(configuration.isPressed ? 0.25 : 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
