import SwiftUI

@main
struct MouseMeasureApp: App {
    @StateObject private var viewModel = MouseMeasureViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopupView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "computermouse.fill")
                Text(viewModel.statusBarText)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
