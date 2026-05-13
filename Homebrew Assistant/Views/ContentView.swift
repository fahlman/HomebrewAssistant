//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: NavigationSplitView composition, sidebar/detail/bottom navigation
//  placement, and selected-step bottom-bar configuration dispatch.
//  Does not own: Workflow session controller construction details, SD card
//  validation policy, scoped filesystem access lifecycle, recipe catalog loading,
//  public recipe parsing, downloads, staging, file writes, workflow item rendering,
//  sidebar row rendering, detail-view routing, or bottom button rendering.
//  Uses: WorkflowSessionController for session state, WorkflowSidebarView,
//  WorkflowDetailView, BottomNavigationView, and WorkflowBottomBarConfiguration
//  supplied by the selected step controller.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionController = WorkflowSessionController()

    var body: some View {
        NavigationSplitView {
            WorkflowSidebarView(coordinator: sessionController.coordinator)
        } detail: {
            VStack(spacing: 0) {
                WorkflowDetailView(
                    coordinator: sessionController.coordinator,
                    sdSelectionController: sessionController.sdSelectionController,
                    homebrewDashboardController: sessionController.homebrewDashboardController
                )
                BottomNavigationView(
                    coordinator: sessionController.coordinator,
                    configuration: bottomBarConfiguration
                )
            }
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    private var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        switch sessionController.coordinator.selectedItem {
        case .fixed(.sdCardSelection):
            return sessionController.sdSelectionController.bottomBarConfiguration
        case .fixed(.chooseItems):
            return sessionController.homebrewDashboardController.bottomBarConfiguration
        case nil:
            return .automatic
        }
    }
}

#Preview {
    ContentView()
}
