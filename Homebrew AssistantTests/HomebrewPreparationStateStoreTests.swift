//
//  HomebrewPreparationStateStoreTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies per-homebrew preparation status storage behavior.
//  Covers: Default missing-option status, storing and retrieving status, reset,
//  single-option removal, and pruning to allowed option IDs.
//  Does not cover: Dashboard rendering, filtering, sorting, homebrew selection,
//  downloads, verification, archive extraction, staging, SD card writes, or
//  workflow navigation.
//

import Testing
@testable import Homebrew_Assistant

struct HomebrewPreparationStateStoreTests {
    @Test func missingOptionReturnsNotSelectedStatus() {
        let store = HomebrewPreparationStateStore()

        #expect(store[.builtIn(.wilbrand)] == .notSelected)
    }

    @Test func subscriptStoresAndReturnsPreparationStatus() {
        var store = HomebrewPreparationStateStore()

        store[.builtIn(.hackMii)] = .downloading(progress: 0.5)

        #expect(store[.builtIn(.hackMii)] == .downloading(progress: 0.5))
    }

    @Test func resetClearsStoredStatuses() {
        var store = HomebrewPreparationStateStore()

        store[.builtIn(.wilbrand)] = .setupRequired
        store[.builtIn(.hackMii)] = .readyToDownload
        store.reset()

        #expect(store[.builtIn(.wilbrand)] == .notSelected)
        #expect(store[.builtIn(.hackMii)] == .notSelected)
    }

    @Test func removeStatusClearsOnlyRequestedOption() {
        var store = HomebrewPreparationStateStore()

        store[.builtIn(.wilbrand)] = .setupRequired
        store[.builtIn(.hackMii)] = .readyToDownload
        store.removeStatus(for: .builtIn(.wilbrand))

        #expect(store[.builtIn(.wilbrand)] == .notSelected)
        #expect(store[.builtIn(.hackMii)] == .readyToDownload)
    }

    @Test func removeStatusesExceptAllowedOptionIDsPrunesDiscardedOptions() {
        var store = HomebrewPreparationStateStore()

        store[.builtIn(.wilbrand)] = .setupRequired
        store[.builtIn(.hackMii)] = .readyToDownload
        store[.publicRecipe("discarded")] = .failed(message: "No longer selected")

        store.removeStatuses(except: [.builtIn(.wilbrand), .publicRecipe("discarded")])

        #expect(store[.builtIn(.wilbrand)] == .setupRequired)
        #expect(store[.builtIn(.hackMii)] == .notSelected)
        #expect(store[.publicRecipe("discarded")] == .failed(message: "No longer selected"))
    }
}
