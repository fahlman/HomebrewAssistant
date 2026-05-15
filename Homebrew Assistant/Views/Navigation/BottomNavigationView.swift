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
//  Uses: WorkflowBottomBarState from the session and WorkflowStepAction
//

import Foundation
internal import SwiftUI

struct BottomNavigationView: View {
    let state: WorkflowBottomBarState
    let goBack: () -> Void
    let goForward: () -> Void

    init(
        state: WorkflowBottomBarState,
        goBack: @escaping () -> Void,
        goForward: @escaping () -> Void
    ) {
        self.state = state
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
        if state.canGoBack {
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
            ForEach(Array(state.configuration.contextualActions.enumerated()), id: \.offset) { index, contextualAction in
                contextualActionButton(contextualAction, isDefaultCandidate: index == defaultContextualActionIndex)
            }

            nextButton
        }
    }

    @ViewBuilder
    private var nextButton: some View {
        if isNextDefault {
            Button(String(localized: "navigation.next")) {
                goForward()
            }
            .disabled(!resolvedCanGoForward)
            .keyboardShortcut(.defaultAction)
        } else {
            Button(String(localized: "navigation.next")) {
                goForward()
            }
            .disabled(!resolvedCanGoForward)
        }
    }

    @ViewBuilder
    private func contextualActionButton(
        _ action: WorkflowStepAction,
        isDefaultCandidate: Bool
    ) -> some View {
        if isContextualActionDefault && isDefaultCandidate && action.isEnabled {
            Button(title(for: action)) {
                action.perform()
            }
            .disabled(!action.isEnabled)
            .keyboardShortcut(.defaultAction)
        } else {
            Button(title(for: action)) {
                action.perform()
            }
            .disabled(!action.isEnabled)
        }
    }

    private func title(for action: WorkflowStepAction) -> String {
        let localizedFormat = String(localized: String.LocalizationValue(action.titleKey))
        guard !action.titleArguments.isEmpty else {
            return localizedFormat
        }

        return String(
            format: localizedFormat,
            locale: Locale.current,
            arguments: action.titleArguments.map { $0 as CVarArg }
        )
    }

    private var resolvedCanGoForward: Bool {
        state.configuration.canGoForwardOverride ?? state.canGoForward
    }

    private var isContextualActionDefault: Bool {
        defaultContextualActionIndex != nil
    }

    private var defaultContextualActionIndex: Int? {
        guard case .contextualAction(let index) = state.configuration.defaultAction,
              state.configuration.contextualActions.indices.contains(index),
              state.configuration.contextualActions[index].isEnabled else {
            return nil
        }

        return index
    }

    private var isNextDefault: Bool {
        switch state.configuration.defaultAction {
        case .next:
            resolvedCanGoForward
        case .contextualAction:
            false
        case nil:
            resolvedCanGoForward
        }
    }
}
