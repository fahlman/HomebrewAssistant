//
//  FixedStep.swift
//  Homebrew Assistant
//
//  Purpose: Defines fixed app-owned workflow steps that are not recipe or
//  internal workflow preparation items.
//  Owns: Fixed step identities for SD card selection and choosing homebrew,
//  plus localization keys, SF Symbol names, and fixed-step ordering.
//  Does not own: View layout, scoped filesystem access, download execution,
//  disk writes, recipe loading, internal workflow behavior, homebrew preparation
//  state, review/write/success dashboard states, or navigation execution.
//  Consumed by: WorkflowCoordinator and views/controllers that need fixed-step
//  identity, title, icon, or ordering metadata.
//

import Foundation

enum FixedStep: String, CaseIterable, Identifiable, Hashable {
    case sdCardSelection
    case chooseItems

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .sdCardSelection:
            "workflow.fixedStep.grantDiskAccess.title"
        case .chooseItems:
            "workflow.fixedStep.chooseHomebrew.title"
        }
    }

    var systemImageName: String {
        switch self {
        case .sdCardSelection:
            "sdcard"
        case .chooseItems:
            "checklist"
        }
    }

    var sortOrder: Int {
        switch self {
        case .sdCardSelection:
            0
        case .chooseItems:
            1
        }
    }
}
