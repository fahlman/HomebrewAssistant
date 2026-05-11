//
//  HackMiiView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the placeholder UI for the app-owned HackMii workflow.
//  Owns: Content-unavailable presentation for HackMii while preparation UI is
//  not yet implemented.
//  Does not own: HackMii instructions, browser actions, file selection,
//  validation, progress, archive extraction, staging, SD card writes, workflow
//  navigation, or preparation execution.
//  Uses: Localizable strings for placeholder title and description.
//

import SwiftUI

struct HackMiiView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.internal.hackMii.title"),
            systemImage: "externaldrive.badge.plus",
            description: Text(String(localized: "hackMii.placeholder.description"))
        )
    }
}
