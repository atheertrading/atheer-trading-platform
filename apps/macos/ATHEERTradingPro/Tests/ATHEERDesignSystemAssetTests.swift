import XCTest
@testable import ATHEERTradingPro

final class ATHEERDesignSystemAssetTests: XCTestCase {
    func testPrimitivePalettePreservesExistingSourceValues() {
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.graphiteBlack, 0x121212)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.deepTeal, 0x093732)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.midnightNavy, 0x001F3F)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.currentTurquoise, 0x00CEC8)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.gold, 0xFFD700)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.positive, 0x00C853)
        XCTAssertEqual(ATHEERDesignTokens.PrimitiveColor.negative, 0xD32F2F)
    }

    func testExistingTypographyAndSpacingContractsRemainStable() {
        XCTAssertEqual(ATHEERDesignTokens.Spacing.compact, 6)
        XCTAssertEqual(ATHEERDesignTokens.Spacing.standard, 12)
        XCTAssertEqual(ATHEERDesignTokens.Spacing.section, 18)
        XCTAssertEqual(ATHEERDesignTokens.Spacing.page, 24)
        XCTAssertEqual(ATHEERDesignTokens.Radius.small, 6)
        XCTAssertEqual(ATHEERDesignTokens.Radius.standard, 8)
        XCTAssertEqual(ATHEERDesignTokens.Radius.large, 12)
    }

    func testControlTargetsReflectMacOSBaselineAndSeparateTouchExpansion() {
        XCTAssertEqual(ATHEERDesignTokens.ControlMetrics.macOSDefaultTarget, 28)
        XCTAssertEqual(ATHEERDesignTokens.ControlMetrics.macOSMinimumTarget, 20)
        XCTAssertEqual(ATHEERDesignTokens.ControlMetrics.touchExpandedTarget, 44)
        XCTAssertGreaterThan(
            ATHEERDesignTokens.ControlMetrics.touchExpandedTarget,
            ATHEERDesignTokens.ControlMetrics.macOSDefaultTarget
        )
    }

    func testBrandMarkPathIsGeometricAndScalesWithItsContainer() {
        let shape = ATHEERBrandMarkShape()
        let small = shape.path(in: CGRect(x: 0, y: 0, width: 100, height: 100)).boundingRect
        let large = shape.path(in: CGRect(x: 0, y: 0, width: 200, height: 200)).boundingRect

        XCTAssertEqual(large.width / small.width, 2, accuracy: 0.0001)
        XCTAssertEqual(large.height / small.height, 2, accuracy: 0.0001)
        XCTAssertGreaterThan(small.width, 90)
        XCTAssertGreaterThan(small.height, 85)
    }
}
