//
//  HomebrewPreparationStatus.swift
//  Homebrew Assistant
//
//  Purpose: Defines the shared preparation lifecycle state for selected homebrew.
//  Owns: Preparation status cases, localized status title lookup, optional
//  progress values, and optional failure-message extraction.
//  Does not own: Homebrew selection, setup validation, downloads, checksum
//  verification, SD card writes, failure recovery, workflow navigation, SwiftUI
//  styling, or status color mapping.
//  Uses: Localizable strings for user-facing status titles.
//

import Foundation

nonisolated enum HomebrewPreparationStatus: Equatable, Sendable {
    case notSelected
    case setupRequired
    case readyToDownload
    case downloading(progress: Double)
    case downloaded
    case readyToExtract
    case extracting
    case generatedArchiveRequired
    case readyToSave
    case saving(progress: Double)
    case saved
    case failed(message: String)

    var title: String {
        switch self {
        case .notSelected:
            String(localized: "chooseHomebrew.status.notSelected")
        case .setupRequired:
            String(localized: "chooseHomebrew.status.setupRequired")
        case .readyToDownload:
            String(localized: "chooseHomebrew.status.readyToDownload")
        case .downloading:
            String(localized: "chooseHomebrew.status.downloading")
        case .downloaded:
            String(localized: "chooseHomebrew.status.downloaded")
        case .readyToExtract:
            String(localized: "chooseHomebrew.status.readyToExtract")
        case .extracting:
            String(localized: "chooseHomebrew.status.extracting")
        case .generatedArchiveRequired:
            String(localized: "chooseHomebrew.status.generatedArchiveRequired")
        case .readyToSave:
            String(localized: "chooseHomebrew.status.readyToSave")
        case .saving:
            String(localized: "chooseHomebrew.status.saving")
        case .saved:
            String(localized: "chooseHomebrew.status.saved")
        case .failed:
            String(localized: "chooseHomebrew.status.failed")
        }
    }


    var progressValue: Double? {
        switch self {
        case .downloading(let progress), .saving(let progress):
            progress
        case .notSelected, .setupRequired, .readyToDownload, .downloaded, .readyToExtract, .extracting, .generatedArchiveRequired, .readyToSave, .saved, .failed:
            nil
        }
    }

    var failureMessage: String? {
        switch self {
        case .failed(let message):
            message
        case .notSelected, .setupRequired, .readyToDownload, .downloading, .downloaded, .readyToExtract, .extracting, .generatedArchiveRequired, .readyToSave, .saving, .saved:
            nil
        }
    }
}
