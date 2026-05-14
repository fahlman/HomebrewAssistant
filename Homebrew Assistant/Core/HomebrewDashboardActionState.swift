//
//  HomebrewDashboardActionState.swift
//  Homebrew Assistant
//
//  Purpose: Models the Choose Homebrew dashboard's current action phase.
//  Owns: Dashboard action-state identity, mapping from action state to
//  preparation action intent, and bottom-bar configuration for dashboard actions.
//  Does not own: Dashboard selection state, preparation status storage, option
//  rendering, preparation execution, download execution, save/export execution,
//  workflow navigation, or bottom-bar rendering.
//  Used by: HomebrewDashboardController.
//

import Foundation

enum HomebrewDashboardActionState: Equatable {
    case nothingSelected
    case needsWilbrandSetup
    case readyToDownload
    case readyToSave
    case complete

    var preparationAction: HomebrewPreparationAction? {
        switch self {
        case .needsWilbrandSetup:
            .setUpWilbrand
        case .readyToDownload:
            .download
        case .readyToSave:
            .save
        case .nothingSelected, .complete:
            nil
        }
    }

    func bottomBarConfiguration(controller: HomebrewDashboardController) -> WorkflowBottomBarConfiguration {
        let contextualActions = contextualActions(controller: controller)

        return WorkflowBottomBarConfiguration(
            contextualActions: contextualActions,
            canGoForwardOverride: contextualActions.isEmpty ? nil : false,
            defaultAction: contextualActions.isEmpty ? nil : .contextualAction(index: contextualActions.startIndex)
        )
    }

    private func contextualActions(controller: HomebrewDashboardController) -> [WorkflowStepAction] {
        guard let preparationAction else { return [] }

        return [
            WorkflowStepAction(
                titleKey: preparationAction.titleKey,
                systemImageName: preparationAction.systemImageName
            ) { [weak controller] in
                controller?.perform(preparationAction)
            }
        ]
    }
}
