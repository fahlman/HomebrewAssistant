//
//  InternalWorkflowCatalog.swift
//  Homebrew Assistant
//
//  Purpose: Provides app-owned internal workflow metadata that is selectable
//  through the Homebrew dashboard.
//  Owns: Internal workflow kinds, the internal workflow definition protocol,
//  ordered internal workflow metadata, internal option metadata, and mapping
//  internal workflow kinds to their workflow definition objects.
//  Does not own: Public recipe catalog loading, public recipe parsing, network
//  downloads, SD card writes, workflow execution, or view rendering.
//  Uses: WilbrandWorkflow and HackMiiWorkflow for workflow-specific
//  definitions.
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

struct InternalWorkflowCatalog {
    let workflows: [InternalWorkflowKind]

    init(workflows: [InternalWorkflowKind] = InternalWorkflowKind.allCases) {
        self.workflows = workflows.sorted { first, second in
            first.sortOrder < second.sortOrder
        }
    }


    var homebrewOptions: [HomebrewOption] {
        workflows.map { kind in
            HomebrewOption(kind: kind)
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
