import Sparkle
import SwiftUI

// This view model class manages Sparkle's updater controller
final class SparkleUpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    init() {
        // Initialize the updater controller
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    @Published var canCheckForUpdates = false

    var updater: SPUUpdater {
        updaterController.updater
    }
}

// This is a view that can be used in SwiftUI menus for checking for updates
struct CheckForUpdatesView: View {
    @ObservedObject private var updaterViewModel: SparkleUpdaterViewModel

    init(updaterViewModel: SparkleUpdaterViewModel) {
        self.updaterViewModel = updaterViewModel
    }

    var body: some View {
        Button("Check for Updates...") {
            updaterViewModel.updater.checkForUpdates()
        }
        .disabled(!updaterViewModel.canCheckForUpdates)
        .onAppear {
            updaterViewModel.canCheckForUpdates =
                updaterViewModel.updater.canCheckForUpdates
        }
    }
}
