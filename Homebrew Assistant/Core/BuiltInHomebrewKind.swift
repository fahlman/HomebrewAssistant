//
//  BuiltInHomebrewKind.swift
//  Homebrew Assistant
//
//  Purpose: Identifies built-in homebrew options provided by the app.
//  Owns: Built-in homebrew identity for Wilbrand and HackMii.
//  Does not own: Public recipe identity, catalog loading, preparation execution,
//  downloads, staging, SD card writes, workflow navigation, or view rendering.
//  Used by: Built-in homebrew definitions, HomebrewDefinition, HomebrewOption,
//  and dashboard tests.
//

import Foundation

enum BuiltInHomebrewKind: String, CaseIterable, Identifiable, Hashable {
    case wilbrand
    case hackMii

    var id: String { rawValue }
}
