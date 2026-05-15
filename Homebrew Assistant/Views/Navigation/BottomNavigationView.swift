//
//  BottomNavigationView.swift
//  Homebrew Assistant
//
//  Purpose: Presents shared bottom navigation and step-specific actions.
//  Owns: Lower-left Quit/Back placement, lower-right action placement,
//  contextual action rendering, Next button rendering, default-button assignment,
//  and disabled/enabled button presentation.
//  Does not own: Action availability decisions, workflow transition policy,
//  workflow reset policy, selected-step state, or risky operation execution.
//  Uses: Explicit navigation availability/actions from the session,
//  WorkflowBottomBarConfiguration for bottom-bar behavior, and WorkflowStepAction
//  for contextual action metadata and execution.
//

internal import SwiftUI

struct BottomNavigationView: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let configuration: WorkflowBottomBarConfiguration
    let goBack: () -> Void
    let goForward: () -> Void

    init(
        canGoBack: Bool,
        canGoForward: Bool,
        configuration: WorkflowBottomBarConfiguration = .automatic,
        goBack: @escaping () -> Void,
        goForward: @escaping () -> Void
    ) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.configuration = configuration
        self.goBack = goBack
        self.goForward = goForward
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
        if canGoBack {
            Button(String(localized: "navigation.back")) {
                goBack()
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
            ForEach(Array(configuration.contextualActions.enumerated()), id: \.offset) { index, contextualAction in
                contextualActionButton(contextualAction, isDefaultCandidate: index == defaultContextualActionIndex)
            }

            nextButton
        }
    }

    private var nextButton: some View {
        Button(String(localized: "navigation.next")) {
            goForward()
        }
        .disabled(!resolvedCanGoForward)
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

    private var resolvedCanGoForward: Bool {
        configuration.canGoForwardOverride ?? canGoForward
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
            resolvedCanGoForward
        case .contextualAction:
            false
        case nil:
            resolvedCanGoForward
        }
    }
}
