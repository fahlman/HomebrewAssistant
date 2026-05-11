//
//  WorkflowBottomBarConfigurationTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies bottom-bar configuration model defaults and stored values.
//  Covers: Automatic/default configuration, contextual actions, forward-button
//  override, and default-action selection.
//  Does not cover: Button rendering, workflow navigation execution, contextual
//  action side effects, or SwiftUI default-button behavior.
//

import Testing
@testable import Homebrew_Assistant

struct WorkflowBottomBarConfigurationTests {
    @Test func automaticConfigurationHasNoActionsOverridesOrDefaultAction() {
        let configuration = WorkflowBottomBarConfiguration.automatic

        #expect(configuration.contextualActions.isEmpty)
        #expect(configuration.canGoForwardOverride == nil)
        #expect(configuration.defaultAction == nil)
    }

    @Test func customConfigurationPreservesContextualActionsAndForwardOverride() {
        let action = WorkflowStepAction(
            titleKey: "test.action.title",
            systemImageName: "gearshape",
            isEnabled: true,
            perform: {}
        )

        let configuration = WorkflowBottomBarConfiguration(
            contextualActions: [action],
            canGoForwardOverride: false,
            defaultAction: .next
        )

        #expect(configuration.contextualActions.count == 1)
        #expect(configuration.contextualActions[0].titleKey == "test.action.title")
        #expect(configuration.contextualActions[0].systemImageName == "gearshape")
        #expect(configuration.contextualActions[0].isEnabled)
        #expect(configuration.canGoForwardOverride == false)

        guard case .next = configuration.defaultAction else {
            Issue.record("Expected default action to be .next")
            return
        }
    }

    @Test func customConfigurationPreservesContextualDefaultActionIndex() {
        let configuration = WorkflowBottomBarConfiguration(
            contextualActions: [
                WorkflowStepAction(titleKey: "first", perform: {}),
                WorkflowStepAction(titleKey: "second", perform: {})
            ],
            defaultAction: .contextualAction(index: 1)
        )

        guard case let .contextualAction(index) = configuration.defaultAction else {
            Issue.record("Expected contextual default action")
            return
        }

        #expect(index == 1)
    }
}
