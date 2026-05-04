//
//  FixedStep.swift
//  Homebrew Assistant
//
//  Purpose: Defines fixed app-owned workflow steps that are not recipe or
//  internal workflow preparation items.
//  Owns: Fixed step identities for Grant Disk Access, Choose Homebrew, Review Setup,
//  Write and Verify Files, and Success, plus fixed-step ordering and basic metadata.
//  Does not own: View layout, scoped filesystem access, download execution,
//  disk writes, recipe loading, or internal workflow behavior.
//  Delegates to: WorkflowCoordinator for runtime transitions and step-specific
//  views/services for presentation and work.
//

import Foundation

enum FixedStep: String, CaseIterable, Identifiable, Hashable {
    case sdCardSelection
    case chooseItems
    case reviewSetup
    case writeAndVerifyFiles
    case success

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .sdCardSelection:
            "workflow.fixedStep.grantDiskAccess.title"
        case .chooseItems:
            "workflow.fixedStep.chooseHomebrew.title"
        case .reviewSetup:
            "workflow.fixedStep.reviewSetup.title"
        case .writeAndVerifyFiles:
            "workflow.fixedStep.writeAndVerifyFiles.title"
        case .success:
            "workflow.fixedStep.success.title"
        }
    }

    var systemImageName: String {
        switch self {
        case .sdCardSelection:
            "sdcard"
        case .chooseItems:
            "checklist"
        case .reviewSetup:
            "doc.text.magnifyingglass"
        case .writeAndVerifyFiles:
            "square.and.arrow.down"
        case .success:
            "checkmark.circle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .sdCardSelection:
            0
        case .chooseItems:
            1
        case .reviewSetup:
            900
        case .writeAndVerifyFiles:
            901
        case .success:
            902
        }
    }
}
