//
//  HomebrewOptionID.swift
//  Homebrew Assistant
//
//  Purpose: Provides collision-proof identity for dashboard homebrew options.
//  Owns: Source-qualified option identity for built-in and public recipe
//  homebrew.
//  Does not own: Display metadata, recipe parsing, preparation policy,
//  selection state, preparation state storage, workflow navigation, or view
//  rendering.
//  Used by: HomebrewDefinition, HomebrewOption, dashboard selection state, and
//  preparation state storage.
//

import Foundation

nonisolated struct HomebrewOptionID: Hashable, Sendable {
    let rawValue: String

    private init(rawValue: String) {
        self.rawValue = rawValue
    }

    static func builtIn(_ kind: BuiltInHomebrewKind) -> HomebrewOptionID {
        HomebrewOptionID(rawValue: "builtIn:\(kind.rawValue)")
    }

    static func publicRecipe(_ id: String) -> HomebrewOptionID {
        HomebrewOptionID(rawValue: "publicRecipe:\(id)")
    }
}
