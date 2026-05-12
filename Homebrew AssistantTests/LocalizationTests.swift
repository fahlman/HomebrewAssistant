//
//  LocalizationTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies that localization keys used by current routed views and
//  dashboard-driven homebrew options resolve to localized strings.
//  Covers: Built-in workflow titles, Choose Homebrew dashboard copy, bottom-bar
//  actions, and preparation status labels.
//  Does not cover: Full localization completeness, formatting, pluralization,
//  accessibility copy, or every user-facing string in the app.
//

import Foundation
import Testing

struct LocalizationTests {
    @Test func currentWorkflowAndDashboardLocalizationKeysExist() {
        let keys = [
            "workflow.internal.wilbrand.title",
            "workflow.internal.hackMii.title",
            "chooseHomebrew.availableHomebrew.sectionTitle",
            "chooseHomebrew.availableHomebrew.description",
            "chooseHomebrew.filter.label",
            "chooseHomebrew.sort.label",
            "chooseHomebrew.category.all",
            "chooseHomebrew.sort.category",
            "chooseHomebrew.sort.alphabetical",
            "chooseHomebrew.setupWilbrand.button",
            "chooseHomebrew.download.button",
            "chooseHomebrew.save.button",
            "chooseHomebrew.status.notSelected",
            "chooseHomebrew.status.setupRequired",
            "chooseHomebrew.status.readyToDownload",
            "chooseHomebrew.status.readyToSave",
        ]

        for key in keys {
            #expect(localizedString(for: key) != key, "Missing localization for key: \(key)")
        }
    }

    private func localizedString(for key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
