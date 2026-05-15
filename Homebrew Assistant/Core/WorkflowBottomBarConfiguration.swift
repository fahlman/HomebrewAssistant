//
//  WorkflowBottomBarConfiguration.swift
//  Homebrew Assistant
//
//  Purpose: Describes bottom-bar behavior and session-level bottom-bar state.
//  Owns: Contextual action list, forward-button enabled override,
//  default-action selection, and the session snapshot consumed by the bottom-bar
//  view.
//  Does not own: Contextual action execution details, workflow navigation
//  execution, button rendering, step UI presentation, file pickers, downloads,
//  writes, or validation policy.
//  Uses: WorkflowStepAction for contextual action metadata and execution.
//

import Foundation

struct WorkflowBottomBarConfiguration {
    enum DefaultAction: Equatable {
        case contextualAction(index: Int)
        case next
    }

    let contextualActions: [WorkflowStepAction]
    let canGoForwardOverride: Bool?
    let defaultAction: DefaultAction?

    init(
        contextualActions: [WorkflowStepAction] = [],
        canGoForwardOverride: Bool? = nil,
        defaultAction: DefaultAction? = nil
    ) {
        self.contextualActions = contextualActions
        self.canGoForwardOverride = canGoForwardOverride
        self.defaultAction = defaultAction
    }

    static let automatic = WorkflowBottomBarConfiguration()
}

struct WorkflowBottomBarState {
    let canGoBack: Bool
    let canGoForward: Bool
    let configuration: WorkflowBottomBarConfiguration

    init(
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        configuration: WorkflowBottomBarConfiguration = .automatic
    ) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.configuration = configuration
    }

    static let initial = WorkflowBottomBarState()
}
