//
//  HomebrewAssistantApp.swift
//  Homebrew Assistant
//
//  Purpose: Defines the SwiftUI app entry point and creates the main window scene.
//  Owns: App launch declaration, main scene creation, and app-level dependency
//  injection through the SwiftUI scene.
//  Does not own: Workflow business logic, disk operations, scoped SD card access,
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
