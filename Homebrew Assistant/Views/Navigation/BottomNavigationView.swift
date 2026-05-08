//
//  BottomNavigationView.swift
//  Homebrew Assistant
//
//  Purpose: Presents shared bottom navigation and step-specific actions.
//  Owns: Lower-left Quit/Back placement, lower-right action placement,
//  optional contextual step-action placement before the default Next action,
//  rendering the configured default button, and disabled/enabled button presentation.
//  Does not own: Action availability decisions, workflow transitions, or risky
//  operation execution.
//  Delegates to: WorkflowCoordinator for navigation availability and user intent handling,
//  and WorkflowStepAction for optional contextual step-action metadata.
//

import SwiftUI

struct BottomNavigationView: View {
    @ObservedObject var coordinator: WorkflowCoordinator
    let configuration: WorkflowBottomBarConfiguration

    init(
        coordinator: WorkflowCoordinator,
        configuration: WorkflowBottomBarConfiguration = .automatic
    ) {
        self.coordinator = coordinator
        self.configuration = configuration
    }

    var body: some View {
        HStack {
            leftAction

            Spacer()

            rightActions
        }
        .controlSize(.regular)
        .padding()
    }

    @ViewBuilder
    private var leftAction: some View {
        if coordinator.canGoBack {
            Button(String(localized: "navigation.back")) {
                coordinator.goBack()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command])
        } else {
            Button(String(localized: "navigation.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private var rightActions: some View {
        HStack {
            if shouldShowStartNewWorkflow {
                Button(String(localized: "workflow.action.startNewWorkflow")) {
                    coordinator.resetWorkflow()
                }
            }

            ForEach(Array(configuration.contextualActions.enumerated()), id: \.offset) { index, contextualAction in
                contextualActionButton(contextualAction, isDefaultCandidate: index == defaultContextualActionIndex)
            }

            nextButton
        }
    }

    private var nextButton: some View {
        Button(String(localized: "navigation.next")) {
            coordinator.goForward()
        }
        .disabled(!canGoForward)
        .keyboardShortcut(isNextDefault ? .defaultAction : nil)
    }

    private func contextualActionButton(
        _ action: WorkflowStepAction,
        isDefaultCandidate: Bool
    ) -> some View {
        Button(String(localized: String.LocalizationValue(action.titleKey))) {
            action.perform()
        }
        .disabled(!action.isEnabled)
        .keyboardShortcut(isContextualActionDefault && isDefaultCandidate && action.isEnabled ? .defaultAction : nil)
    }

    private var canGoForward: Bool {
        configuration.canGoForwardOverride ?? coordinator.canGoForward
    }

    private var isContextualActionDefault: Bool {
        defaultContextualActionIndex != nil
    }

    private var defaultContextualActionIndex: Int? {
        guard case .contextualAction(let index) = configuration.defaultAction,
              configuration.contextualActions.indices.contains(index),
              configuration.contextualActions[index].isEnabled else {
            return nil
        }

        return index
    }

    private var isNextDefault: Bool {
        switch configuration.defaultAction {
        case .next:
            canGoForward
        case .contextualAction:
            false
        case nil:
            canGoForward
        }
    }

    private var shouldShowStartNewWorkflow: Bool {
        guard case .fixed(.success)? = coordinator.selectedItem else {
            return false
        }

        return true
    }
}
