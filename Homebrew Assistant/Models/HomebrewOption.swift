//
//  HomebrewOption.swift
//  Homebrew Assistant
//
//  Purpose: Defines the shared selectable homebrew option model used by the
//  Choose Homebrew step.
//  Owns: Source-qualified option identity, localized name, summary key, category, icon reference,
//  preparation kind, approved download request, and definition source mapping.
//  Does not own: Option selection state, filtering UI, sorting UI, recipe
//  loading, downloads, preparation execution, or workflow navigation.
//  Uses: HomebrewDefinition for homebrew option construction.
//

import Foundation

nonisolated struct HomebrewOption: Identifiable, Sendable {
    nonisolated enum Source: Hashable, Sendable {
        case builtIn(BuiltInHomebrewKind)
        case publicRecipe(id: String)
    }

    let id: HomebrewOptionID
    let name: String
    let summaryKey: String
    let category: HomebrewCategory
    let systemImageName: String
    let preparationKind: HomebrewPreparationKind
    let setupURL: URL?
    let downloadRequest: HomebrewDownloadRequest?
    let source: Source

    var summary: String {
        String(localized: String.LocalizationValue(summaryKey))
    }

    init(
        id: HomebrewOptionID,
        name: String,
        summaryKey: String,
        category: HomebrewCategory,
        systemImageName: String,
        preparationKind: HomebrewPreparationKind,
        setupURL: URL? = nil,
        downloadRequest: HomebrewDownloadRequest? = nil,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.summaryKey = summaryKey
        self.category = category
        self.systemImageName = systemImageName
        self.preparationKind = preparationKind
        self.setupURL = setupURL
        self.downloadRequest = downloadRequest
        self.source = source
    }

    init(definition: HomebrewDefinition) {
        let source: Source
        switch definition.source {
        case .builtIn(let kind):
            source = .builtIn(kind)
        case .publicRecipe(let id):
            source = .publicRecipe(id: id)
        }

        self.init(
            id: definition.id,
            name: definition.name,
            summaryKey: definition.summaryKey,
            category: definition.category,
            systemImageName: definition.systemImageName,
            preparationKind: definition.preparationKind,
            setupURL: definition.setupURL,
            downloadRequest: definition.downloadRequest,
            source: source
        )
    }

}
