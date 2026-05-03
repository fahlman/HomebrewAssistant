//
//  HackMiiWorkflow.swift
//  Homebrew Assistant
//
//  Purpose: Defines app-owned HackMii bootstrap behavior and trust boundaries.
//  Owns: Approved HackMii source metadata, expected files, checksum requirements
//  when available, staging rules, and copy intent for the final manifest.
//  Does not own: Public recipe metadata, Homebrew Assistant Recipes updates,
//  generic download implementation, generic checksum calculation, SD card writes,
//  or user-facing copy.
//  Delegates to: ItemPreparationService and DiagnosticsLog.
//

import Foundation

struct HackMiiWorkflow: InternalWorkflowDefinition {
    let kind: InternalWorkflowKind = .hackMii

    var titleKey: String { kind.titleKey }
    var systemImageName: String { kind.systemImageName }
    var sortOrder: Int { kind.sortOrder }
}
