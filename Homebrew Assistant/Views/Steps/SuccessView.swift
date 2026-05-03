//
//  SuccessView.swift
//  Homebrew Assistant
//
//  Purpose: Presents completion, verification status, next steps, and user-initiated eject.
//  Owns: Success summary presentation, prepared item summary presentation,
//  verification result presentation, next-step instruction presentation, Eject
//  button presentation, and Start New Workflow presentation.
//  Does not own: Eject implementation, cleanup implementation, verification
//  execution, or workflow reset implementation.
//  Delegates to: WorkflowCoordinator, DiskManager, and DiagnosticsLog.
//

import SwiftUI

struct SuccessView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.fixedStep.success.title"),
            systemImage: "checkmark.circle",
            description: Text(String(localized: "success.placeholder.description"))
        )
    }
}
