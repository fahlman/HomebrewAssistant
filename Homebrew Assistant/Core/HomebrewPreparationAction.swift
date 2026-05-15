//
//  HomebrewPreparationAction.swift
//  Homebrew Assistant
//
//  Purpose: Defines dashboard preparation action intents for selected homebrew.
//  Owns: Preparation action identity and bottom-bar button metadata for setup,
//  download, and save intents.
//  Does not own: Dashboard action-state derivation, preparation status storage,
//  browser launching, download execution, verification, staging, SD card writes,
//  or workflow navigation.
//  Used by: HomebrewDashboardController and HomebrewDashboardActionState.
//

import Foundation

enum HomebrewPreparationAction: Equatable {
    case setUp(optionName: String?)
    case download
    case save

    var titleKey: String {
        switch self {
        case .setUp(let optionName):
            optionName == nil ? "chooseHomebrew.setupSelected.button" : "chooseHomebrew.setupNamed.button"
        case .download:
            "chooseHomebrew.download.button"
        case .save:
            "chooseHomebrew.save.button"
        }
    }

    var titleArguments: [String] {
        switch self {
        case .setUp(let optionName):
            optionName.map { [$0] } ?? []
        case .download, .save:
            []
        }
    }

    var systemImageName: String {
        switch self {
        case .setUp:
            "safari"
        case .download:
            "arrow.down.circle"
        case .save:
            "square.and.arrow.down"
        }
    }
}
