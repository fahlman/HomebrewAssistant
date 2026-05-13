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

@MainActor
struct HomebrewPreparationStateStoreTests {
    @Test func missingOptionReturnsNotSelectedStatus() {
        let store = HomebrewPreparationStateStore()

        #expect(store["wilbrand"] == .notSelected)
    }

    @Test func subscriptStoresAndReturnsPreparationStatus() {
        var store = HomebrewPreparationStateStore()

        store["hackMii"] = .downloading(progress: 0.5)

        #expect(store["hackMii"] == .downloading(progress: 0.5))
    }

    @Test func resetClearsStoredStatuses() {
        var store = HomebrewPreparationStateStore()

        store["wilbrand"] = .setupRequired
        store["hackMii"] = .readyToDownload
        store.reset()

        #expect(store["wilbrand"] == .notSelected)
        #expect(store["hackMii"] == .notSelected)
    }

    @Test func removeStatusClearsOnlyRequestedOption() {
        var store = HomebrewPreparationStateStore()

        store["wilbrand"] = .setupRequired
        store["hackMii"] = .readyToDownload
        store.removeStatus(for: "wilbrand")

        #expect(store["wilbrand"] == .notSelected)
        #expect(store["hackMii"] == .readyToDownload)
    }

    @Test func removeStatusesExceptAllowedOptionIDsPrunesDiscardedOptions() {
        var store = HomebrewPreparationStateStore()

        store["wilbrand"] = .setupRequired
        store["hackMii"] = .readyToDownload
        store["discarded"] = .failed(message: "No longer selected")

        store.removeStatuses(except: ["wilbrand", "discarded"])

        #expect(store["wilbrand"] == .setupRequired)
        #expect(store["hackMii"] == .notSelected)
        #expect(store["discarded"] == .failed(message: "No longer selected"))
    }
}
