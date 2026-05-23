//
//  WilbrandHomebrewDefinition.swift
//  Homebrew Assistant
//
//  Purpose: Provides the built-in Wilbrand dashboard definition.
//  Owns: Wilbrand built-in homebrew definition metadata.
//  Does not own: Dashboard selection state, browser launching, file selection,
//  archive validation, staging, SD card writes, workflow navigation, or
//  user-facing view layout.
//  Used by: BuiltInHomebrewCatalog.
//

import Foundation

enum WilbrandHomebrewDefinition {
    static let definition = HomebrewDefinition(
        id: .builtIn(.wilbrand),
        name: String(localized: "workflow.internal.wilbrand.title"),
        summaryKey: "chooseHomebrew.wilbrand.description",
        category: .exploits,
        systemImageName: "ladybug",
        sortOrder: 100,
        preparationKind: .setupRequired,
        setupURL: URL(string: "https://wilbrand.donut.eu.org")!,
        downloadRequest: nil,
        source: .builtIn(.wilbrand)
    )
}
