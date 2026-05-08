//
//  InternalWorkflowCatalog.swift
//  Homebrew Assistant
//
//  Purpose: Provides app-owned internal workflow item definitions that are selectable alongside public recipes.
//  Owns: Internal workflow kinds, internal workflow definition protocol, internal
//  workflow list, ordering metadata, category metadata, localization keys, icon
//  references, and mapping internal workflow identifiers to bundled app-owned behavior.
//  Does not own: Public recipe catalog loading, public recipe parsing, network
//  downloads, SD card writes, or view rendering.
//  Delegates to: WilbrandWorkflow, HackMiiWorkflow, and WorkflowCoordinator.
//

import Foundation

enum InternalWorkflowKind: String, CaseIterable, Identifiable, Hashable {
    case wilbrand
    case hackMii

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .wilbrand:
            "workflow.internal.wilbrand.title"
        case .hackMii:
            "workflow.internal.hackMii.title"
        }
    }

    var summaryKey: String {
        switch self {
        case .wilbrand:
            "chooseHomebrew.wilbrand.description"
        case .hackMii:
            "chooseHomebrew.hackMii.description"
        }
    }

    var category: HomebrewCategory {
        switch self {
        case .wilbrand:
            .exploits
        case .hackMii:
            .installers
        }
    }

    var systemImageName: String {
        switch self {
        case .wilbrand:
            "ladybug"
        case .hackMii:
            "hammer"
        }
    }

    var sortOrder: Int {
        switch self {
        case .wilbrand:
            100
        case .hackMii:
            101
        }
    }

}

enum HomebrewCategory: Int, CaseIterable, Comparable, Identifiable {
    case apps
    case exploits
    case installers
    case utilities
    case wads

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .apps:
            "chooseHomebrew.category.apps"
        case .exploits:
            "chooseHomebrew.category.exploits"
        case .installers:
            "chooseHomebrew.category.installers"
        case .utilities:
            "chooseHomebrew.category.utilities"
        case .wads:
            "chooseHomebrew.category.wads"
        }
    }

    var title: String {
        String(localized: String.LocalizationValue(titleKey))
    }

    static func < (lhs: HomebrewCategory, rhs: HomebrewCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct InternalWorkflowCatalog {
    let workflows: [InternalWorkflowKind]

    init(workflows: [InternalWorkflowKind] = InternalWorkflowKind.allCases) {
        self.workflows = workflows.sorted { first, second in
            first.sortOrder < second.sortOrder
        }
    }

    var workflowItems: [WorkflowItem] {
        workflows.map { kind in
            .internalWorkflow(kind)
        }
    }

    func workflow(for kind: InternalWorkflowKind) -> any InternalWorkflowDefinition {
        switch kind {
        case .wilbrand:
            WilbrandWorkflow()
        case .hackMii:
            HackMiiWorkflow()
        }
    }
}

protocol InternalWorkflowDefinition {
    var kind: InternalWorkflowKind { get }
    var titleKey: String { get }
    var summaryKey: String { get }
    var category: HomebrewCategory { get }
    var systemImageName: String { get }
    var sortOrder: Int { get }
}
