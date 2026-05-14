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
        id: BuiltInHomebrewKind.wilbrand.id,
        name: String(localized: String.LocalizationValue(BuiltInHomebrewKind.wilbrand.titleKey)),
        summaryKey: BuiltInHomebrewKind.wilbrand.summaryKey,
        category: BuiltInHomebrewKind.wilbrand.category,
        systemImageName: BuiltInHomebrewKind.wilbrand.systemImageName,
        sortOrder: BuiltInHomebrewKind.wilbrand.sortOrder,
        source: .builtIn(.wilbrand)
    )
}
