//
//  HomebrewAssistantApp.swift
//  Homebrew Assistant
//
//  Purpose: Defines the SwiftUI app entry point and creates the main window scene.
//  Owns: App launch declaration and main scene creation.
//  Does not own: Workflow business logic, disk operations, scoped SD card access,
//  downloads, staging, file writes, or dependency construction.
//  Uses: ContentView as the main window content.
//

internal import SwiftUI

@main
struct HomebrewAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
