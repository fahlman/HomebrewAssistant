//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: Main window layout composition, placement of sidebar, detail, and
//  bottom navigation regions, and creation/injection of shared view-session
//  controllers needed by multiple app regions.
//  Does not own: Workflow business logic, disk operations, scoped filesystem access,
//  downloads, staging, or file writes.
//  Delegates to: WorkflowSidebarView, WorkflowDetailView, BottomNavigationView,
//  shared workflow state, and SDSelectionController.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = WorkflowCoordinator()
    @StateObject private var sdSelectionController = SDSelectionController()

    var body: some View {
        NavigationSplitView {
            WorkflowSidebarView(coordinator: coordinator)
        } detail: {
            VStack(spacing: 0) {
                WorkflowDetailView(
                    coordinator: coordinator,
                    sdSelectionController: sdSelectionController
                )
                BottomNavigationView(
                    coordinator: coordinator,
                    configuration: bottomBarConfiguration
                )
            }
        }
        .frame(minWidth: 720, minHeight: 450)
    }
    
    private var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        guard case .fixed(.sdCardSelection)? = coordinator.selectedItem else {
            return .automatic
        }

        let isValidSDCardSelected = sdSelectionController.readiness?.isReady == true

        return WorkflowBottomBarConfiguration(
            contextualAction: WorkflowStepAction(
                titleKey: "sdSelection.chooseSDCard.button",
                systemImageName: "sdcard"
            ) {
                sdSelectionController.presentVolumeImporter()
            },
            canGoForwardOverride: isValidSDCardSelected,
            defaultAction: isValidSDCardSelected ? .next : .contextualAction
        )
    }
}

private extension SDCardReadiness {
    var isReady: Bool {
        if case .ready = self {
            return true
        }

        return false
    }
}

#Preview {
    ContentView()
}
