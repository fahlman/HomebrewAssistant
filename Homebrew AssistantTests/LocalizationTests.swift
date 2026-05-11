//
//  LocalizationTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies that localization keys used by routed placeholder views resolve to localized strings.
//  Covers: Wilbrand, HackMii, and public recipe placeholder title/description keys.
//  Does not cover: Full localization completeness, formatting, pluralization,
//  accessibility copy, or every user-facing string in the app.
//
import Foundation
import Testing

struct LocalizationTests {
    @Test func routedPlaceholderLocalizationKeysExist() {
        let keys = [
            "workflow.internal.wilbrand.title",
            "workflow.internal.hackMii.title",
            "wilbrand.placeholder.description",
            "hackMii.placeholder.description",
            "recipeStep.title",
            "recipeStep.placeholder.description",
        ]

        for key in keys {
            #expect(localizedString(for: key) != key, "Missing localization for key: \(key)")
        }
    }

    private func localizedString(for key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
