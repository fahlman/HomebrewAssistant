//
//  HomebrewPreparationStateStore.swift
//  Homebrew Assistant
//
//  Purpose: Stores per-homebrew preparation state for dashboard-driven homebrew preparation.
//  Owns: Preparation status by homebrew option ID and session-only preparation
//  state cleanup, plus value models for preparation state transitions.
//  Does not own: Dashboard layout, filtering, sorting, homebrew selection,
//  downloads, verification, archive extraction, staging, SD card writes, or
//  workflow navigation, transition recording, or logging.
//  Uses: HomebrewPreparationStatus for display-ready preparation status values.
//

import Foundation

struct HomebrewPreparationStateStore {
    private var statusesByOptionID: [HomebrewOption.ID: HomebrewPreparationStatus]
    private var preparedPayloadURLsByOptionID: [HomebrewOption.ID: URL]
    private var extractedPayloadDirectoryURLsByOptionID: [HomebrewOption.ID: URL]

    init(
        statusesByOptionID: [HomebrewOption.ID: HomebrewPreparationStatus] = [:],
        preparedPayloadURLsByOptionID: [HomebrewOption.ID: URL] = [:],
        extractedPayloadDirectoryURLsByOptionID: [HomebrewOption.ID: URL] = [:]
    ) {
        self.statusesByOptionID = statusesByOptionID
        self.preparedPayloadURLsByOptionID = preparedPayloadURLsByOptionID
        self.extractedPayloadDirectoryURLsByOptionID = extractedPayloadDirectoryURLsByOptionID
    }

    subscript(optionID: HomebrewOption.ID) -> HomebrewPreparationStatus {
        get {
            statusesByOptionID[optionID, default: .notSelected]
        }
        set {
            statusesByOptionID[optionID] = newValue
        }
    }

    mutating func reset() {
        statusesByOptionID.removeAll()
        preparedPayloadURLsByOptionID.removeAll()
        extractedPayloadDirectoryURLsByOptionID.removeAll()
    }

    mutating func removeStatus(for optionID: HomebrewOption.ID) {
        statusesByOptionID.removeValue(forKey: optionID)
        preparedPayloadURLsByOptionID.removeValue(forKey: optionID)
        extractedPayloadDirectoryURLsByOptionID.removeValue(forKey: optionID)
    }

    mutating func removeStatuses(except allowedOptionIDs: Set<HomebrewOption.ID>) {
        statusesByOptionID = statusesByOptionID.filter { optionID, _ in
            allowedOptionIDs.contains(optionID)
        }
        preparedPayloadURLsByOptionID = preparedPayloadURLsByOptionID.filter { optionID, _ in
            allowedOptionIDs.contains(optionID)
        }
        extractedPayloadDirectoryURLsByOptionID = extractedPayloadDirectoryURLsByOptionID.filter { optionID, _ in
            allowedOptionIDs.contains(optionID)
        }
    }

    func preparedPayloadURL(for optionID: HomebrewOption.ID) -> URL? {
        preparedPayloadURLsByOptionID[optionID]
    }

    mutating func setPreparedPayloadURL(
        _ payloadURL: URL,
        for optionID: HomebrewOption.ID
    ) {
        preparedPayloadURLsByOptionID[optionID] = payloadURL
    }

    func extractedPayloadDirectoryURL(for optionID: HomebrewOption.ID) -> URL? {
        extractedPayloadDirectoryURLsByOptionID[optionID]
    }

    mutating func setExtractedPayloadDirectoryURL(
        _ directoryURL: URL,
        for optionID: HomebrewOption.ID
    ) {
        extractedPayloadDirectoryURLsByOptionID[optionID] = directoryURL
    }
}

nonisolated struct HomebrewPreparationStateTransition: Equatable, Sendable {
    let optionID: HomebrewOption.ID
    let optionName: String
    let previousStatus: HomebrewPreparationStatus
    let newStatus: HomebrewPreparationStatus
    let reason: HomebrewPreparationStateTransitionReason
}

nonisolated enum HomebrewPreparationStateTransitionReason: Equatable, Sendable {
    case selected
    case deselected
    case downloadStarted
    case downloadProgressed
    case setupCompleted
    case browserOpened
    case generatedArchiveImported
    case generatedArchiveImportCancelled
    case generatedArchiveImportFailed
    case downloadCompleted
    case downloadFailed
    case extractionStarted
    case extractionCompleted
    case extractionFailed
    case reconciled
    case saveStarted
    case saveCompleted
}
