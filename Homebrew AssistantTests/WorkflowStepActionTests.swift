//
//  WorkflowStepActionTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies contextual workflow-step action metadata and execution.
//  Covers: Title key storage, optional icon storage, enabled state defaults,
//  disabled state storage, and action closure invocation.
//  Does not cover: Bottom-bar configuration, button rendering, workflow
//  navigation execution, validation policy, file pickers, downloads, or writes.
//

import Testing
@testable import Homebrew_Assistant

struct WorkflowStepActionTests {
    @Test func actionStoresTitleIconEnabledStateAndClosure() {
        var didRun = false
        let action = WorkflowStepAction(
            titleKey: "test.action.title",
            systemImageName: "gearshape",
            isEnabled: true,
            perform: { didRun = true }
        )

        #expect(action.titleKey == "test.action.title")
        #expect(action.titleArguments.isEmpty)
        #expect(action.systemImageName == "gearshape")
        #expect(action.isEnabled)

        action.perform()

        #expect(didRun)
    }

    @Test func actionDefaultsToEnabledAndNoIcon() {
        let action = WorkflowStepAction(
            titleKey: "test.default.title",
            perform: {}
        )

        #expect(action.titleKey == "test.default.title")
        #expect(action.titleArguments.isEmpty)
        #expect(action.systemImageName == nil)
        #expect(action.isEnabled)
    }

    @Test func actionStoresTitleArguments() {
        let action = WorkflowStepAction(
            titleKey: "test.named.title",
            titleArguments: ["Wilbrand"],
            perform: {}
        )

        #expect(action.titleKey == "test.named.title")
        #expect(action.titleArguments == ["Wilbrand"])
    }

    @Test func disabledActionStoresDisabledState() {
        let action = WorkflowStepAction(
            titleKey: "test.disabled.title",
            isEnabled: false,
            perform: {}
        )

        #expect(!action.isEnabled)
    }
}
