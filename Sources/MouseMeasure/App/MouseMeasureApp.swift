import SwiftUI

@main
struct MouseMeasureApp: App {
    @StateObject private var viewModel = MouseMeasureViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopupView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "cursorarrow.motionlines")
                Text(viewModel.statusBarText)
                    .monospacedDigit()
                    .font(.caption)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
