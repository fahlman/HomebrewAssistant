//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: Main window layout composition and placement of sidebar, detail, and
//  bottom navigation regions.
//  Does not own: Workflow business logic, disk operations, permission checks,
//  downloads, staging, or file writes.
//  Delegates to: WorkflowSidebarView, WorkflowDetailView, BottomNavigationView,
//  and shared workflow state.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Homebrew Assistant")
            .frame(minWidth: 800, minHeight: 520)
    }
}

#Preview {
    ContentView()
}
