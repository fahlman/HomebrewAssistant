//
//  HackMiiHomebrewDefinition.swift
//  Homebrew Assistant
//
//  Purpose: Provides the built-in HackMii dashboard definition.
//  Owns: HackMii built-in homebrew definition metadata.
//  Does not own: Dashboard selection state, download behavior, checksum
//  validation, staging, SD card writes, workflow navigation, or user-facing view
//  layout.
//  Used by: BuiltInHomebrewCatalog.
//

import Foundation

enum HackMiiHomebrewDefinition {
    static let definition = HomebrewDefinition(
        id: BuiltInHomebrewKind.hackMii.id,
        name: String(localized: "workflow.internal.hackMii.title"),
        summaryKey: "chooseHomebrew.hackMii.description",
        category: .installers,
        systemImageName: "hammer",
        sortOrder: 101,
        source: .builtIn(.hackMii)
    )
}
