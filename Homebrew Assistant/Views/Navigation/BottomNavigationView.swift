//
//  BottomNavigationView.swift
//  Homebrew Assistant
//
//  Purpose: Presents shared bottom navigation and step-specific actions.
//  Owns: Lower-left Quit/Back placement, lower-right action placement, default
//  button presentation rules, and disabled/enabled button presentation.
//  Does not own: Action availability decisions, workflow transitions, or risky
//  operation execution.
//  Delegates to: WorkflowCoordinator for available actions and user intent handling.
//

import SwiftUI

struct BottomNavigationView: View {
    @ObservedObject var coordinator: WorkflowCoordinator

    var body: some View {
        HStack {
            leftAction

            Spacer()

            rightActions
        }
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

            Button(String(localized: "navigation.next")) {
                coordinator.goForward()
            }
            .disabled(!coordinator.canGoForward)
        }
    }

    private var shouldShowStartNewWorkflow: Bool {
        guard case .fixed(.success)? = coordinator.selectedItem else {
            return false
        }

        return true
    }
}
