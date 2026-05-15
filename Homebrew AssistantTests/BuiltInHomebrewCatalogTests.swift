//
//  BuiltInHomebrewCatalogTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies the built-in homebrew catalog metadata.
//  Covers: Wilbrand and HackMii definitions, catalog ordering, and generated
//  dashboard homebrew options.
//  Does not cover: Preparation behavior, downloads, archive extraction, staging,
//  SD card writes, workflow navigation, or view rendering.
//

import Testing
@testable import Homebrew_Assistant

struct BuiltInHomebrewCatalogTests {
    @Test func catalogContainsWilbrandAndHackMiiInSortOrder() {
        let catalog = BuiltInHomebrewCatalog()

        let sortedDefinitions = catalog.definitions
            .sorted { $0.sortOrder < $1.sortOrder }

        #expect(sortedDefinitions.map(\.source) == [
            .builtIn(.wilbrand),
            .builtIn(.hackMii)
        ])
    }

    @Test func homebrewOptionsAreGeneratedFromBuiltInHomebrewDefinitions() {
        let catalog = BuiltInHomebrewCatalog()

        #expect(catalog.homebrewOptions.map(\.source) == [
            .builtIn(.wilbrand),
            .builtIn(.hackMii)
        ])
        #expect(catalog.homebrewOptions.map(\.id) == [
            HomebrewOptionID.builtIn(.wilbrand),
            HomebrewOptionID.builtIn(.hackMii)
        ])
        #expect(catalog.homebrewOptions.map(\.name) == [
            "Wilbrand",
            "HackMii"
        ])
    }
}
