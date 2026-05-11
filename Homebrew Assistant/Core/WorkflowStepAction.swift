//
//  WorkflowStepAction.swift
//  Homebrew Assistant
//
//  Purpose: Describes one optional contextual workflow-step action.
//  Owns: Action title key, optional action icon reference, enabled state, and
//  action execution closure.
//  Does not own: Bottom-bar configuration, workflow navigation execution, step
//  UI presentation, file pickers, downloads, writes, validation policy, or button
//  rendering.
//  Consumed by: WorkflowBottomBarConfiguration, BottomNavigationView, and
//  step-specific controllers/coordinators that provide contextual workflow actions.
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
