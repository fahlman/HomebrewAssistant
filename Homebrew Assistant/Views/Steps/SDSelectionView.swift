//
//  SDSelectionView.swift
//  Homebrew Assistant
//
//  Purpose: Presents SD card selection and validation state.
//  Owns: Choose SD Card action presentation, SD card validation result
//  presentation, Open Disk Utility affordance presentation, and user-facing
//  explanation of scoped SD card access.
//  Does not own: Scoped access lifecycle, Disk Arbitration metadata resolution,
//  SD card readiness policy, file writes, or eject behavior.
//  Delegates to: WorkflowCoordinator, ScopedAccessManager, DiskManager, and SDCardReadiness.
//

import SwiftUI

struct SDSelectionView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "workflow.fixedStep.sdCardSelection.title"),
            systemImage: "sdcard",
            description: Text(String(localized: "sdSelection.placeholder.description"))
        )
    }
}
