import AppKit
import SwiftUI

@MainActor
enum ShareService {
    static func shareImage<V: View>(from view: V) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0  // 2x for retina → 1200x630 actual pixels

        guard let nsImage = renderer.nsImage else { return }

        let picker = NSSharingServicePicker(items: [nsImage])

        // Find the key window's content view to anchor the share sheet
        guard let contentView = NSApp.keyWindow?.contentView else { return }
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
    }
}
