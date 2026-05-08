//
//  WorkflowStepAction.swift
//  Homebrew Assistant
//
//  Purpose: Describes optional contextual actions for the selected workflow step.
//  Owns: User-facing action title keys, optional icon references, enabled states,
//  and action execution closures.
//  Does not own: Button placement, workflow navigation, step UI presentation,
//  file pickers, downloads, writes, or validation policy.
//  Delegates to: BottomNavigationView for presentation and step-specific
//  controllers/coordinators for behavior.
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
