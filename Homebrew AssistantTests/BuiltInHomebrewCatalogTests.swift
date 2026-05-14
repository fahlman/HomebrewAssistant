//
//  BuiltInHomebrewCatalogTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies the built-in homebrew catalog metadata.
//  Covers: Wilbrand and HackMii catalog entries, catalog ordering, and generated
//  dashboard homebrew options.
//  Does not cover: Preparation behavior, downloads, archive extraction, staging,
//  SD card writes, workflow navigation, or view rendering.
//

import Testing
@testable import Homebrew_Assistant

@MainActor
struct BuiltInHomebrewCatalogTests {
    @Test func catalogContainsWilbrandAndHackMiiInSortOrder() {
        let catalog = BuiltInHomebrewCatalog()

        let sortedKinds = catalog.homebrewKinds
            .sorted { $0.sortOrder < $1.sortOrder }

        #expect(sortedKinds == [.wilbrand, .hackMii])
    }

    @Test func homebrewOptionsAreGeneratedFromBuiltInHomebrewKinds() {
        let catalog = BuiltInHomebrewCatalog()

        #expect(catalog.homebrewOptions.map(\.source) == [
            .internalWorkflow(.wilbrand),
            .internalWorkflow(.hackMii)
        ])
        #expect(catalog.homebrewOptions.map(\.id) == [
            BuiltInHomebrewKind.wilbrand.id,
            BuiltInHomebrewKind.hackMii.id
        ])
        #expect(catalog.homebrewOptions.map(\.name) == [
            "Wilbrand",
            "HackMii"
        ])
    }
}
