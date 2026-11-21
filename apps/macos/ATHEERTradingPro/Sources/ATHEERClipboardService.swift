import AppKit
import Foundation
import UniformTypeIdentifiers

/// Clipboard boundary for non-sensitive presentation values and explicit export payloads.
/// It never reads secrets or invokes broker/trading services.
@MainActor
enum ATHEERClipboardService {
    @discardableResult
    static func copy(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    /// Writes a validated JSON handoff payload plus a plain JSON text fallback.
    @discardableResult
    static func copyJSON<Payload: Encodable>(
        _ payload: Payload,
        contentType: UTType
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let customType = NSPasteboard.PasteboardType(contentType.identifier)
        let jsonType = NSPasteboard.PasteboardType(UTType.json.identifier)
        let textFallback = String(decoding: data, as: UTF8.self)

        let customWritten = pasteboard.setData(data, forType: customType)
        let jsonWritten = pasteboard.setData(data, forType: jsonType)
        let textWritten = pasteboard.setString(textFallback, forType: .string)

        return customWritten || jsonWritten || textWritten
    }
}
