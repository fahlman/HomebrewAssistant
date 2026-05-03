//
//  WilbrandWorkflow.swift
//  Homebrew Assistant
//
//  Purpose: Defines app-owned Wilbrand behavior and trust boundaries.
//  Owns: Approved Wilbrand URL or source pattern, browser-to-file-selection flow
//  expectations, expected archive shape, validation requirements, and staging metadata.
//  Does not own: Public recipe metadata, Homebrew Assistant Recipes updates,
//  generic archive extraction implementation, SD card writes, or user-facing copy.
//  Delegates to: ItemPreparationService and DiagnosticsLog.
//

import Foundation

struct WilbrandWorkflow: InternalWorkflowDefinition {
    let kind: InternalWorkflowKind = .wilbrand

    var titleKey: String { kind.titleKey }
    var systemImageName: String { kind.systemImageName }
    var sortOrder: Int { kind.sortOrder }
}
