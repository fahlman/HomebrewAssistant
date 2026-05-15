//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: NavigationSplitView composition, sidebar/detail/bottom navigation
//  placement, and session-provided bottom-bar state/action display.
//  Does not own: Workflow session orchestration, SD card validation policy,
//  scoped filesystem access lifecycle, recipe catalog loading,
//  public recipe parsing, downloads, staging, file writes, workflow item rendering,
//  sidebar row rendering, detail-view routing, or bottom button rendering.
//  Uses: WorkflowSessionController for session state, WorkflowSidebarView,
//  WorkflowDetailView and BottomNavigationView.
//

internal import SwiftUI

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
                    state: sessionController.bottomBarState,
                    goBack: sessionController.goBack,
                    goForward: sessionController.goForward
                )
            }
        }
        .frame(minWidth: 720, minHeight: 520)
    }
}

#Preview {
    ContentView()
}
