//
//  WorkflowItem.swift
//  Homebrew Assistant
//
//  Purpose: Represents an item in the generated workflow sidebar and navigation model.
//  Owns: Fixed-step workflow item identifiers, localization keys, icon references,
//  and ordering metadata.
//  Does not own: Homebrew dashboard options, public recipe metadata, internal
//  workflow metadata, runtime workflow decisions, availability/completion state,
//  scoped filesystem access, disk operations, downloads, writes, or UI rendering.
//  Uses: FixedStep for item-specific metadata.
//

import Foundation

enum WorkflowItem: Identifiable, Hashable {
    case fixed(FixedStep)

    var id: String {
        switch self {
        case .fixed(let fixedStep):
            "fixed.\(fixedStep.id)"
        }
    }

    var titleKey: String {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.titleKey
        }
    }

    var systemImageName: String {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.systemImageName
        }
    }

    var sortOrder: Int {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.sortOrder
        }
    }

    var isFixedStep: Bool {
        if case .fixed = self {
            true
        } else {
            false
        }
    }
}
