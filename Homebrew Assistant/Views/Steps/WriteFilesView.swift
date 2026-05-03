//
//  WriteFilesView.swift
//  Homebrew Assistant
//
//  Purpose: Presents write and verification progress.
//  Owns: Per-file progress presentation, overall progress presentation, current
//  operation presentation, recoverable/fatal error presentation, and safe
//  cancellation affordance presentation when available.
//  Does not own: File copying, verification execution, write diagnostics,
//  SD card validation, or staging layout creation.
//  Delegates to: WorkflowCoordinator, SDWriteService, and DiagnosticsLog.
//

import SwiftUI

struct WriteFilesView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.fixedStep.writeAndVerifyFiles.title"),
            systemImage: "square.and.arrow.down",
            description: Text(String(localized: "writeFiles.placeholder.description"))
        )
    }
}
