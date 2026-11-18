import CoreGraphics

/// Shared geometry for the native shell and the IPDS review canvases.
/// All values are logical points; backing-store pixel dimensions are exports only.
enum IPDSViewportMetrics {
    /// Existing minimums declared by the SwiftUI application.
    static let minimumWindowSize = CGSize(width: 900, height: 600)
    static let minimumDetailSize = CGSize(width: 620, height: 520)
    static let brokerManagementSheetSize = CGSize(width: 760, height: 560)

    /// Existing PR #89 shell constraints.
    static let sidebarMinimumWidth: CGFloat = 190
    static let sidebarIdealWidth: CGFloat = 224
    static let sidebarMaximumWidth: CGFloat = 280
    static let commandBarHeight: CGFloat = 64

    /// Wide design target, not a supported-minimum claim.
    static let wideDesignCanvasSize = CGSize(width: 1440, height: 900)
    static let exportScale: CGFloat = 2

    static var wideExportCanvasSize: CGSize {
        CGSize(
            width: wideDesignCanvasSize.width * exportScale,
            height: wideDesignCanvasSize.height * exportScale
        )
    }
}
