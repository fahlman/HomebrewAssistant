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
        id: HomebrewOptionID.builtIn(.hackMii),
        name: String(localized: "workflow.internal.hackMii.title"),
        summaryKey: "chooseHomebrew.hackMii.description",
        category: HomebrewCategory.installers,
        systemImageName: "hammer",
        sortOrder: 101,
        preparationKind: HomebrewPreparationKind.downloadable,
        downloadRequest: HomebrewDownloadRequest(
            approvedBaseURL: URL(string: "https://bootmii.org/")!,
            payloadFileName: "hackmii_installer_v1.2.zip",
            expectedSHA256: "32b7406956860ffb50d46f83e5fb6b8d67cd2612781cd97619d0c2371c84c945"
        ),
        source: HomebrewDefinitionSource.builtIn(.hackMii)
    )
}
