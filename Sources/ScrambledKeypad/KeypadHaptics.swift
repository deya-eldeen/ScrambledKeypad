#if canImport(UIKit)
import UIKit
#endif

enum KeypadHaptics {
    static func impact(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
