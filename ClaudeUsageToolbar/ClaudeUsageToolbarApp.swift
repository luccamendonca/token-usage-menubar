import AppKit
import SwiftUI

@main
struct ClaudeUsageToolbarApp: App {
    @StateObject private var model = UsageViewModel()

    init() {
        // When run as a plain binary (SwiftPM), there is no Info.plist LSUIElement.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra(content: {
            MenuContentView(model: model)
        }, label: {
            Text(model.menuBarTitle)
                .monospacedDigit()
        })
        .menuBarExtraStyle(.window)
    }
}
