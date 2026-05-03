//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: Main window layout composition and placement of sidebar, detail, and
//  bottom navigation regions.
//  Does not own: Workflow business logic, disk operations, scoped filesystem access,
//  downloads, staging, or file writes.
//  Delegates to: WorkflowSidebarView, WorkflowDetailView, BottomNavigationView,
//  and shared workflow state.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = WorkflowCoordinator()

    var body: some View {
        NavigationSplitView {
            WorkflowSidebarView(coordinator: coordinator)
        } detail: {
            VStack(spacing: 0) {
                WorkflowDetailView(coordinator: coordinator)
                BottomNavigationView(coordinator: coordinator)
            }
        }
        .frame(minWidth: 720, minHeight: 445)
    }
}

#Preview {
    ContentView()
}
