//
//  WorkflowBottomBarConfiguration.swift
//  Homebrew Assistant
//
//  Purpose: Describes bottom-bar behavior for the selected workflow item.
//  Owns: Contextual action list, forward-button enabled override, and
//  default-action selection.
//  Does not own: Contextual action execution details, workflow navigation
//  execution, button rendering, step UI presentation, file pickers, downloads,
//  writes, or validation policy.
//  Uses: WorkflowStepAction for contextual action metadata and execution.
//

import Foundation

struct WorkflowBottomBarConfiguration {
    enum DefaultAction {
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
