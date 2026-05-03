//
//  WorkflowStepAction.swift
//  Homebrew Assistant
//
//  Purpose: Describes an optional contextual action for the selected workflow step.
//  Owns: User-facing action title key, optional icon reference, enabled state,
//  and action execution closure.
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
        case contextualAction
        case next
    }

    let contextualAction: WorkflowStepAction?
    let canGoForwardOverride: Bool?
    let defaultAction: DefaultAction?

    init(
        contextualAction: WorkflowStepAction? = nil,
        canGoForwardOverride: Bool? = nil,
        defaultAction: DefaultAction? = nil
    ) {
        self.contextualAction = contextualAction
        self.canGoForwardOverride = canGoForwardOverride
        self.defaultAction = defaultAction
    }

    static let automatic = WorkflowBottomBarConfiguration()
}
