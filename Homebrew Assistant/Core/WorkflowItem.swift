//
//  WorkflowItem.swift
//  Homebrew Assistant
//
//  Purpose: Represents an item in the generated workflow sidebar and navigation model.
//  Owns: Stable workflow identifiers, ordering metadata, step type metadata,
//  localization keys, and icon references.
//  Does not own: Runtime workflow decisions, availability/completion state,
//  scoped filesystem access, disk operations, downloads, writes, or UI rendering.
//  Delegates to: WorkflowCoordinator for runtime state and navigation decisions,
//  and FixedStep, InternalWorkflowCatalog, and Recipe for step-specific metadata.
//

import Foundation

struct PublicRecipeWorkflowMetadata: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let systemImageName: String
    let sortOrder: Int
}

enum WorkflowItem: Identifiable, Hashable {
    case fixed(FixedStep)
    case internalWorkflow(InternalWorkflowKind)
    case publicRecipe(PublicRecipeWorkflowMetadata)

    var id: String {
        switch self {
        case .fixed(let fixedStep):
            "fixed.\(fixedStep.id)"
        case .internalWorkflow(let kind):
            "internal.\(kind.id)"
        case .publicRecipe(let metadata):
            "recipe.\(metadata.id)"
        }
    }

    var titleKey: String {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.titleKey
        case .internalWorkflow(let kind):
            kind.titleKey
        case .publicRecipe(let metadata):
            metadata.titleKey
        }
    }

    var systemImageName: String {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.systemImageName
        case .internalWorkflow(let kind):
            kind.systemImageName
        case .publicRecipe(let metadata):
            metadata.systemImageName
        }
    }

    var sortOrder: Int {
        switch self {
        case .fixed(let fixedStep):
            fixedStep.sortOrder
        case .internalWorkflow(let kind):
            kind.sortOrder
        case .publicRecipe(let metadata):
            metadata.sortOrder
        }
    }

    var isFixedStep: Bool {
        if case .fixed = self {
            true
        } else {
            false
        }
    }

    var isPreparationStep: Bool {
        switch self {
        case .internalWorkflow, .publicRecipe:
            true
        case .fixed:
            false
        }
    }
}
