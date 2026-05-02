//
//  HomebrewAssistantApp.swift
//  Homebrew Assistant
//
//  Purpose: Defines the SwiftUI app entry point and creates the main window scene.
//  Owns: App launch declaration and main scene creation.
//  Does not own: Workflow business logic, disk operations, permission checks,
//  downloads, staging, or file writes.
//  Delegates to: ContentView and app-level dependencies injected through the
//  SwiftUI scene.
//

import SwiftUI

@main
struct HomebrewAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
    }
}
