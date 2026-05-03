//
//  WilbrandView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the app-owned Wilbrand preparation step when selected.
//  Owns: Wilbrand instructions presentation, Open Browser button presentation,
//  Choose File button presentation, and Wilbrand validation/progress/status presentation.
//  Does not own: Approved Wilbrand URL policy, archive extraction implementation,
//  path safety checks, staging implementation, or SD card writes.
//  Delegates to: WorkflowCoordinator, WilbrandWorkflow, and ItemPreparationService.
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
