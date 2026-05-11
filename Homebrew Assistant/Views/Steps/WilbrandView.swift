//
//  WilbrandView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the placeholder UI for the app-owned Wilbrand workflow.
//  Owns: Content-unavailable presentation for Wilbrand while preparation UI is
//  not yet implemented.
//  Does not own: Wilbrand instructions, browser actions, file selection,
//  validation, progress, archive extraction, staging, SD card writes, workflow
//  navigation, or preparation execution.
//  Uses: Localizable strings for placeholder title and description.
//

import SwiftUI

struct WilbrandView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.internal.wilbrand.title"),
            systemImage: "safari",
            description: Text(String(localized: "wilbrand.placeholder.description"))
        )
    }
}
