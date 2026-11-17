import XCTest
@testable import LidToggle

final class PowerStateTests: XCTestCase {
    func testReadsSystemOverrideIndependentlyOfIdleSleepTimer() {
        XCTAssertEqual(PowerState.parse("System-wide power settings:\n SleepDisabled\t1\nCurrently in use:\n sleep 10"), .blocked)
        XCTAssertEqual(PowerState.parse("System-wide power settings:\n SleepDisabled 0\nCurrently in use:\n sleep 0"), .normal)
    }
    func testMissingOverrideUsesDefaultOnlyForRecognizedOutput() {
        XCTAssertEqual(PowerState.parse("System-wide power settings:\nCurrently in use:\n sleep 10"), .normal)
        XCTAssertNil(PowerState.parse(""))
        XCTAssertNil(PowerState.parse("pmset failed"))
        XCTAssertNil(PowerState.parse("SleepDisabled 2"))
        XCTAssertNil(PowerState.parse("SleepDisabled"))
    }
}
