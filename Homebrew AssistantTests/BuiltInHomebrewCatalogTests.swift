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

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
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

    @Test func wilbrandDefinesApprovedSetupURL() throws {
        let catalog = BuiltInHomebrewCatalog()
        let wilbrandOption = try #require(catalog.homebrewOptions.first { option in
            option.source == .builtIn(.wilbrand)
        })

        #expect(wilbrandOption.setupURL?.absoluteString == "https://wilbrand.donut.eu.org")
        #expect(wilbrandOption.downloadRequest == nil)
    }

    @Test func hackMiiDefinesApprovedDownloadRequest() throws {
        let catalog = BuiltInHomebrewCatalog()
        let hackMiiOption = try #require(catalog.homebrewOptions.first { option in
            option.source == .builtIn(.hackMii)
        })

        #expect(hackMiiOption.downloadRequest?.approvedBaseURL.absoluteString == "https://bootmii.org/")
        #expect(hackMiiOption.downloadRequest?.payloadFileName == "hackmii_installer_v1.2.zip")
        #expect(hackMiiOption.downloadRequest?.payloadURL.absoluteString == "https://bootmii.org/hackmii_installer_v1.2.zip")
        #expect(hackMiiOption.downloadRequest?.expectedSHA256 == "32b7406956860ffb50d46f83e5fb6b8d67cd2612781cd97619d0c2371c84c945")
    }
}
