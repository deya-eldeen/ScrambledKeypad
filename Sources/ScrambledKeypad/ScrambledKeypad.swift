import SwiftUI

public struct ScrambledKeypad: View {
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let includeDelete: Bool
    private let includeEnter: Bool
    private let enableHaptics: Bool
    private let enableSizeVariation: Bool
    private let shuffleOnAppear: Bool
    private let scrambleTrigger: Int
    private let onKeyPress: (Int) -> Void
    private let onDelete: (() -> Void)?
    private let onEnter: (() -> Void)?

    @State private var digits: [Int] = ScrambledKeypadDigits.shuffled()
    @State private var scrambleOffsets: [String: CGSize] = [:]
    @State private var variableRows: [KeypadRow] = []

    private let keyHeight: CGFloat = 52
    private let maxVariableRows = 3
    private let maxKeySpan = 3

    public init(
        columns: Int = 3,
        spacing: CGFloat = 12,
        includeDelete: Bool = true,
        includeEnter: Bool = false,
        enableHaptics: Bool = false,
        enableSizeVariation: Bool = false,
        shuffleOnAppear: Bool = true,
        scrambleTrigger: Int = 0,
        onKeyPress: @escaping (Int) -> Void,
        onDelete: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil
    ) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: max(1, columns))
        self.spacing = spacing
        self.includeDelete = includeDelete
        self.includeEnter = includeEnter
        self.enableHaptics = enableHaptics
        self.enableSizeVariation = enableSizeVariation
        self.shuffleOnAppear = shuffleOnAppear
        self.scrambleTrigger = scrambleTrigger
        self.onKeyPress = onKeyPress
        self.onDelete = onDelete
        self.onEnter = onEnter
    }

    public var body: some View {
        Group {
            if enableSizeVariation {
                variableSizeGrid
            } else {
                standardGrid
            }
        }
        .onAppear {
            if shuffleOnAppear {
                digits = ScrambledKeypadDigits.shuffled()
            }
            updateVariableLayout()
        }
        .onChange(of: scrambleTrigger) { _ in
            animateScrambleAndShuffle()
        }
        .onChange(of: enableSizeVariation) { _ in
            updateVariableLayout()
        }
    }

    private var items: [KeyItem] {
        var values = digits.map { KeyItem.digit($0) }
        if includeDelete {
            values.append(.delete)
        }
        if includeEnter {
            values.append(.enter)
        }
        return values
    }

    private var standardGrid: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(items) { item in
                keyView(for: item)
                    .offset(scrambleOffsets[item.id, default: .zero])
            }
        }
    }

    private var variableSizeGrid: some View {
        let rows = variableRows
        let rowCount = max(rows.count, 1)
        let gridHeight = (keyHeight * CGFloat(rowCount)) + (spacing * CGFloat(max(rowCount - 1, 0)))
        return GeometryReader { proxy in
            let rowUnits = variableRowUnits
            let unitWidth = unitWidth(for: rowUnits, totalWidth: proxy.size.width)
            VStack(spacing: spacing) {
                ForEach(rows) { row in
                    HStack(spacing: spacing) {
                        ForEach(row.cells) { cell in
                            if let item = cell.item {
                                keyView(for: item)
                                    .frame(width: cellWidth(span: cell.span, unitWidth: unitWidth), height: keyHeight)
                                    .offset(scrambleOffsets[item.id, default: .zero])
                            } else {
                                Color.clear
                                    .frame(width: cellWidth(span: cell.span, unitWidth: unitWidth), height: keyHeight)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: gridHeight)
    }

    @ViewBuilder
    private func keyView(for item: KeyItem) -> some View {
        switch item {
        case .digit(let value):
            Button {
                KeypadHaptics.impact(enabled: enableHaptics)
                onKeyPress(value)
            } label: {
                Text("\(value)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: keyHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadButtonStyle())
        case .delete:
            Button {
                KeypadHaptics.impact(enabled: enableHaptics)
                onDelete?()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: keyHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadButtonStyle())
            .disabled(onDelete == nil)
            .accessibilityLabel("Delete")
        case .enter:
            Button {
                KeypadHaptics.impact(enabled: enableHaptics)
                onEnter?()
            } label: {
                Text("Enter")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: keyHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadButtonStyle())
            .disabled(onEnter == nil)
            .accessibilityLabel("Enter")
        }
    }

    private func animateScrambleAndShuffle() {
        let ids = items.map(\.id)
        let offsets = ScrambleAnimation.offsets(for: ids)
        withAnimation(.easeOut(duration: ScrambleAnimation.outDuration)) {
            scrambleOffsets = offsets
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ScrambleAnimation.outDuration) {
            withAnimation(.easeIn(duration: ScrambleAnimation.inDuration)) {
                scrambleOffsets = [:]
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ScrambleAnimation.outDuration + ScrambleAnimation.inDuration) {
            digits = ScrambledKeypadDigits.shuffled()
            updateVariableLayout()
        }
    }

    private var variableRowUnits: Int {
        let minimumUnits = Int(ceil(Double(items.count) / Double(maxVariableRows)))
        return max(columns.count + 3, minimumUnits, maxKeySpan)
    }

    private func updateVariableLayout() {
        guard enableSizeVariation else {
            variableRows = []
            return
        }
        variableRows = buildVariableRows()
    }

    private func buildVariableRows() -> [KeypadRow] {
        let rowUnits = variableRowUnits
        let ids = items.map(\.id)
        let capacity = rowUnits * maxVariableRows
        var spans: [String: Int] = Dictionary(uniqueKeysWithValues: ids.map { ($0, 1) })
        var remaining = max(0, capacity - ids.count)
        let shuffledIds = ids.shuffled()
        var cursor = 0
        while remaining > 0 && !shuffledIds.isEmpty {
            let id = shuffledIds[cursor % shuffledIds.count]
            let current = spans[id, default: 1]
            if current < maxKeySpan {
                spans[id] = current + 1
                remaining -= 1
            }
            cursor += 1
            if cursor > shuffledIds.count * maxKeySpan * 2 {
                break
            }
        }

        var rows = buildRows(using: spans, rowUnits: rowUnits)
        var safeGuard = 0
        while rows.count > maxVariableRows && safeGuard < ids.count * maxKeySpan {
            if let idToReduce = ids.reversed().first(where: { spans[$0, default: 1] > 1 }) {
                spans[idToReduce] = max(1, (spans[idToReduce] ?? 1) - 1)
                rows = buildRows(using: spans, rowUnits: rowUnits)
            } else {
                break
            }
            safeGuard += 1
        }
        return rows
    }

    private func buildRows(using spans: [String: Int], rowUnits: Int) -> [KeypadRow] {
        var rows: [KeypadRow] = []
        var current: [KeypadCell] = []
        var remainingInRow = rowUnits
        var rowIndex = 0

        for item in items {
            let span = min(maxKeySpan, max(1, spans[item.id, default: 1]))
            if span > remainingInRow {
                if remainingInRow > 0 {
                    current.append(KeypadCell(id: "spacer-\(rowIndex)-\(current.count)", span: remainingInRow, item: nil))
                }
                rows.append(KeypadRow(id: rowIndex, cells: current))
                rowIndex += 1
                current = []
                remainingInRow = rowUnits
            }
            current.append(KeypadCell(id: item.id, span: span, item: item))
            remainingInRow -= span
        }

        if !current.isEmpty {
            if remainingInRow > 0 {
                current.append(KeypadCell(id: "spacer-\(rowIndex)-\(current.count)", span: remainingInRow, item: nil))
            }
            rows.append(KeypadRow(id: rowIndex, cells: current))
        }
        return rows
    }

    private func unitWidth(for rowUnits: Int, totalWidth: CGFloat) -> CGFloat {
        let units = max(1, rowUnits)
        let totalSpacing = spacing * CGFloat(units - 1)
        let available = max(0, totalWidth - totalSpacing)
        return available / CGFloat(units)
    }

    private func cellWidth(span: Int, unitWidth: CGFloat) -> CGFloat {
        let safeSpan = max(1, span)
        return (unitWidth * CGFloat(safeSpan)) + (spacing * CGFloat(safeSpan - 1))
    }
}

private enum KeyItem: Hashable, Identifiable {
    case digit(Int)
    case delete
    case enter

    var id: String {
        switch self {
        case .digit(let value):
            return "digit-\(value)"
        case .delete:
            return "delete"
        case .enter:
            return "enter"
        }
    }
}

private struct KeypadRow: Identifiable {
    let id: Int
    let cells: [KeypadCell]
}

private struct KeypadCell: Identifiable {
    let id: String
    let span: Int
    let item: KeyItem?
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
