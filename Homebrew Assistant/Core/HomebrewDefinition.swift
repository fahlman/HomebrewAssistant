//
//  HomebrewDefinition.swift
//  Homebrew Assistant
//
//  Purpose: Defines common dashboard metadata for built-in and recipe-provided
//  homebrew.
//  Owns: Source-qualified homebrew definition identity, display metadata, sort order, preparation
//  kind, approved download request metadata, and definition source.
//  Does not own: Dashboard selection state, preparation state transitions, download behavior,
//  validation rules, staging, SD card writes, workflow navigation, or view
//  rendering.
//  Used by: BuiltInHomebrewCatalog, HomebrewOption, built-in homebrew definition
//  files, and future public recipe loading.
//

import Foundation

nonisolated struct HomebrewDefinition: Identifiable, Equatable, Sendable {
    let id: HomebrewOptionID
    let name: String
    let summaryKey: String
    let category: HomebrewCategory
    let systemImageName: String
    let sortOrder: Int
    let preparationKind: HomebrewPreparationKind
    let setupURL: URL?
    let downloadRequest: HomebrewDownloadRequest?
    let source: HomebrewDefinitionSource

    init(
        id: HomebrewOptionID,
        name: String,
        summaryKey: String,
        category: HomebrewCategory,
        systemImageName: String,
        sortOrder: Int,
        preparationKind: HomebrewPreparationKind,
        setupURL: URL? = nil,
        downloadRequest: HomebrewDownloadRequest? = nil,
        source: HomebrewDefinitionSource
    ) {
        self.id = id
        self.name = name
        self.summaryKey = summaryKey
        self.category = category
        self.systemImageName = systemImageName
        self.sortOrder = sortOrder
        self.preparationKind = preparationKind
        self.setupURL = setupURL
        self.downloadRequest = downloadRequest
        self.source = source
    }
}

nonisolated struct HomebrewDownloadRequest: Equatable, Sendable {
    let approvedBaseURL: URL
    let payloadFileName: String
    let expectedSHA256: String?

    var payloadURL: URL {
        approvedBaseURL.appendingPathComponent(payloadFileName)
    }

    init(
        approvedBaseURL: URL,
        payloadFileName: String,
        expectedSHA256: String? = nil
    ) {
        self.approvedBaseURL = approvedBaseURL
        self.payloadFileName = payloadFileName
        self.expectedSHA256 = expectedSHA256
    }
}

nonisolated enum HomebrewPreparationKind: Equatable, Sendable {
    case setupRequired
    case downloadable
}

nonisolated enum HomebrewDefinitionSource: Equatable, Sendable {
    case builtIn(BuiltInHomebrewKind)
    case publicRecipe(id: String)
}
