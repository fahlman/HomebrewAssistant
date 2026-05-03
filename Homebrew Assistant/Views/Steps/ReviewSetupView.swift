//
//  ReviewSetupView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the final review before writing to the SD card.
//  Owns: Selected item summary presentation, user-approved validated SD card
//  summary presentation, staged file/write manifest presentation, required space
//  and overwrite-warning presentation, and final write confirmation presentation.
//  Does not own: Manifest generation, SD card validation, file copying,
//  verification, or source trust decisions.
//  Delegates to: WorkflowCoordinator, StagingManifest, and PreparedTool.
//

import SwiftUI

struct ReviewSetupView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.fixedStep.reviewSetup.title"),
            systemImage: "doc.text.magnifyingglass",
            description: Text(String(localized: "reviewSetup.placeholder.description"))
        )
    }
}
