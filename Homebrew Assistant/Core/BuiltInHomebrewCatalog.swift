//
//  BuiltInHomebrewCatalog.swift
//  Homebrew Assistant
//
//  Purpose: Provides built-in homebrew metadata that is selectable through the
//  Choose Homebrew dashboard.
//  Owns: Ordered built-in homebrew definitions and mapping definitions to
//  dashboard option metadata.
//  Does not own: Built-in homebrew identity, public recipe catalog loading,
//  public recipe parsing, network downloads, SD card writes, preparation
//  execution, workflow navigation, or view rendering.
//  Used by: HomebrewDashboardController and catalog tests.
//

import Foundation

struct BuiltInHomebrewCatalog {
    let definitions: [HomebrewDefinition]

    init(definitions: [HomebrewDefinition] = [
        WilbrandHomebrewDefinition.definition,
        HackMiiHomebrewDefinition.definition
    ]) {
        self.definitions = definitions.sorted { first, second in
            first.sortOrder < second.sortOrder
        }
    }

    var homebrewOptions: [HomebrewOption] {
        definitions.map { definition in
            HomebrewOption(definition: definition)
        }
    }
}
