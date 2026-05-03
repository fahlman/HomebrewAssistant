//
//  HackMiiView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the app-owned HackMii preparation step when selected.
//  Owns: HackMii instructions presentation, Download button presentation,
//  validation/progress/status presentation, and user-facing preparation guidance.
//  Does not own: Approved HackMii source policy, download implementation,
//  checksum calculation, staging implementation, or SD card writes.
//  Delegates to: WorkflowCoordinator, HackMiiWorkflow, and ItemPreparationService.
//

import SwiftUI

struct HackMiiView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.internal.hackMii.title"),
            systemImage: "shippingbox",
            description: Text(String(localized: "hackMii.placeholder.description"))
        )
    }
}
