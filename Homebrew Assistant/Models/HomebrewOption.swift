//
//  HomebrewOption.swift
//  Homebrew Assistant
//
//  Purpose: Defines the shared selectable homebrew option model used by the
//  Choose Homebrew step.
//  Owns: Option identity, localized name, summary key, category, icon reference,
//  and source mapping.
//  Does not own: Option selection state, filtering UI, sorting UI, recipe
//  loading, downloads, internal workflow behavior, or workflow navigation.
//  Uses: InternalWorkflowKind for internal workflow option construction.
//

import Foundation

struct HomebrewOption: Identifiable {
    enum Source: Hashable {
        case internalWorkflow(InternalWorkflowKind)
        case publicRecipe(id: String)
    }

    let id: String
    let name: String
    let summaryKey: String
    let category: HomebrewCategory
    let systemImageName: String
    let source: Source

    var summary: String {
        String(localized: String.LocalizationValue(summaryKey))
    }

    init(
        id: String,
        name: String,
        summaryKey: String,
        category: HomebrewCategory,
        systemImageName: String,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.summaryKey = summaryKey
        self.category = category
        self.systemImageName = systemImageName
        self.source = source
    }

    init(kind: InternalWorkflowKind) {
        self.init(
            id: kind.id,
            name: String(localized: String.LocalizationValue(kind.titleKey)),
            summaryKey: kind.summaryKey,
            category: kind.category,
            systemImageName: kind.systemImageName,
            source: .internalWorkflow(kind)
        )
    }
}
