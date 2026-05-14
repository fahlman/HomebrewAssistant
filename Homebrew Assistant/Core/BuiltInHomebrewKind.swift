//
//  BuiltInHomebrewKind.swift
//  Homebrew Assistant
//
//  Purpose: Identifies built-in homebrew options provided by the app.
//  Owns: Built-in homebrew identity and temporary dashboard metadata for
//  Wilbrand and HackMii.
//  Does not own: Public recipe identity, catalog loading, preparation execution,
//  downloads, staging, SD card writes, workflow navigation, or view rendering.
//  Used by: BuiltInHomebrewCatalog, HomebrewOption, and dashboard tests.
//

import Foundation

enum BuiltInHomebrewKind: String, CaseIterable, Identifiable, Hashable {
    case wilbrand
    case hackMii

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .wilbrand:
            "workflow.internal.wilbrand.title"
        case .hackMii:
            "workflow.internal.hackMii.title"
        }
    }

    var summaryKey: String {
        switch self {
        case .wilbrand:
            "chooseHomebrew.wilbrand.description"
        case .hackMii:
            "chooseHomebrew.hackMii.description"
        }
    }

    var category: HomebrewCategory {
        switch self {
        case .wilbrand:
            .exploits
        case .hackMii:
            .installers
        }
    }

    var systemImageName: String {
        switch self {
        case .wilbrand:
            "ladybug"
        case .hackMii:
            "hammer"
        }
    }

    var sortOrder: Int {
        switch self {
        case .wilbrand:
            100
        case .hackMii:
            101
        }
    }
}
