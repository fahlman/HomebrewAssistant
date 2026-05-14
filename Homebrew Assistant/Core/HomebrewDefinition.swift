//
//  HomebrewDefinition.swift
//  Homebrew Assistant
//
//  Purpose: Defines common dashboard metadata for built-in and recipe-provided
//  homebrew.
//  Owns: Homebrew definition identity, display metadata, sort order, and
//  definition source.
//  Does not own: Dashboard selection state, preparation state, download behavior,
//  validation rules, staging, SD card writes, workflow navigation, or view
//  rendering.
//  Used by: BuiltInHomebrewCatalog, HomebrewOption, built-in homebrew definition
//  files, and future public recipe loading.
//

import Foundation

struct HomebrewDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let summaryKey: String
    let category: HomebrewCategory
    let systemImageName: String
    let sortOrder: Int
    let source: HomebrewDefinitionSource
}

enum HomebrewDefinitionSource: Equatable {
    case builtIn(BuiltInHomebrewKind)
    case publicRecipe(id: String)
}
