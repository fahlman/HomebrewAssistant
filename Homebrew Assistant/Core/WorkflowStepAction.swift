//
//  WorkflowStepAction.swift
//  Homebrew Assistant
//
//  Purpose: Describes optional contextual workflow-step actions and bottom-bar
//  configuration for the selected workflow item.
//  Owns: Action title keys, optional action icon references, enabled states,
//  action execution closures, contextual action lists, forward-button overrides,
//  and default-action selection.
//  Does not own: Workflow navigation execution, step UI presentation, file
//  pickers, downloads, writes, validation policy, or button rendering.
//  Consumed by: BottomNavigationView and step-specific controllers/coordinators
//  that provide contextual workflow actions.
//

import Foundation

struct WorkflowStepAction {
    let titleKey: String
    let systemImageName: String?
    let isEnabled: Bool
    let perform: () -> Void

    init(
        titleKey: String,
        systemImageName: String? = nil,
        isEnabled: Bool = true,
        perform: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.systemImageName = systemImageName
        self.isEnabled = isEnabled
        self.perform = perform
    }
}

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
