//
//  HomebrewPreparationStateStore.swift
//  Homebrew Assistant
//
//  Purpose: Stores per-homebrew preparation state for dashboard-driven homebrew preparation.
//  Owns: Preparation status by homebrew option ID and session-only preparation
//  state cleanup.
//  Does not own: Dashboard layout, filtering, sorting, homebrew selection,
//  downloads, verification, archive extraction, staging, SD card writes, or
//  workflow navigation.
//  Uses: HomebrewPreparationStatus for display-ready preparation status values.
//

import Foundation

struct HomebrewPreparationStateStore {
    private var statusesByOptionID: [HomebrewOption.ID: HomebrewPreparationStatus]

    init(statusesByOptionID: [HomebrewOption.ID: HomebrewPreparationStatus] = [:]) {
        self.statusesByOptionID = statusesByOptionID
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
    }

    mutating func removeStatus(for optionID: HomebrewOption.ID) {
        statusesByOptionID.removeValue(forKey: optionID)
    }

    mutating func removeStatuses(except allowedOptionIDs: Set<HomebrewOption.ID>) {
        statusesByOptionID = statusesByOptionID.filter { optionID, _ in
            allowedOptionIDs.contains(optionID)
        }
    }
}
