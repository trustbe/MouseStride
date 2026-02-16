import SwiftUI

@main
struct MouseStrideApp: App {
    @StateObject private var viewModel = MouseStrideViewModel()

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
