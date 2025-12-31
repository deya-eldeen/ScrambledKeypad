import Testing
@testable import ScrambledKeypad

@Test func shuffledDigitsContainAllDigits() async throws {
    let digits = ScrambledKeypadDigits.shuffled()
    #expect(digits.count == 10)
    #expect(Set(digits) == Set(0...9))
}
