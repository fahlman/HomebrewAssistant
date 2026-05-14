//
//  SDSelectionActionState.swift
//  Homebrew Assistant
//
//  Purpose: Models the SD card selection step's current action phase.
//  Owns: SD card selection action-state identity and bottom-bar configuration
//  mapping for SD card selection actions.
//  Does not own: SD card selection state, scoped access lifecycle, Disk Utility
//  launching, native volume metadata lookup, SD card readiness policy, SwiftUI
//  layout, file writes, workflow navigation, or bottom-bar rendering.
//  Used by: SDSelectionController.
//

import Foundation

enum SDSelectionActionState: Equatable {
    case needsSelection
    case unsupportedFilesystem(hasOpenedDiskUtility: Bool)
    case ready

    func bottomBarConfiguration(controller: SDSelectionController) -> WorkflowBottomBarConfiguration {
        let contextualActions = contextualActions(controller: controller)

        return WorkflowBottomBarConfiguration(
            contextualActions: contextualActions,
            defaultAction: defaultAction(for: contextualActions)
        )
    }

    private func contextualActions(controller: SDSelectionController) -> [WorkflowStepAction] {
        switch self {
        case .needsSelection, .ready:
            [chooseSDCardAction(controller: controller)]
        case .unsupportedFilesystem:
            [
                openDiskUtilityAction(controller: controller),
                chooseSDCardAction(controller: controller)
            ]
        }
    }

    private func defaultAction(for contextualActions: [WorkflowStepAction]) -> WorkflowBottomBarConfiguration.DefaultAction? {
        switch self {
        case .ready:
            .next
        case .needsSelection:
            .contextualAction(index: contextualActions.startIndex)
        case .unsupportedFilesystem(let hasOpenedDiskUtility):
            hasOpenedDiskUtility
                ? .contextualAction(index: contextualActions.index(before: contextualActions.endIndex))
                : .contextualAction(index: contextualActions.startIndex)
        }
    }

    private func openDiskUtilityAction(controller: SDSelectionController) -> WorkflowStepAction {
        WorkflowStepAction(
            titleKey: "sdSelection.openDiskUtility.button",
            systemImageName: "externaldrive.badge.gearshape"
        ) { [weak controller] in
            controller?.openDiskUtility()
        }
    }

    private func chooseSDCardAction(controller: SDSelectionController) -> WorkflowStepAction {
        WorkflowStepAction(
            titleKey: "sdSelection.chooseSDCard.button",
            systemImageName: "sdcard"
        ) { [weak controller] in
            controller?.presentVolumeImporter()
        }
    }
}
