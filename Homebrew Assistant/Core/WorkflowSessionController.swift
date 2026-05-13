//
//  WorkflowSessionController.swift
//  Homebrew Assistant
//
//  Purpose: Owns the active workflow session controllers and cross-controller
//  workflow state synchronization.
//  Owns: WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  and synchronization from SD card readiness into fixed workflow-step
//  completion state.
//  Does not own: App launch, SwiftUI layout, sidebar rendering, detail-view
//  routing, bottom button rendering, SD card validation policy, scoped filesystem
//  access implementation, recipe loading, downloads, staging, or file writes.
//  Uses: WorkflowCoordinator, SDSelectionController, and
//  HomebrewDashboardController for session state.
//

import Combine
import Foundation

@MainActor
final class WorkflowSessionController: ObservableObject {
    let coordinator: WorkflowCoordinator
    let sdSelectionController: SDSelectionController
    let homebrewDashboardController: HomebrewDashboardController

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let coordinator = WorkflowCoordinator()
        let sdSelectionController = SDSelectionController()

        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController(coordinator: coordinator)

        bindSDSelectionReadinessToWorkflowCompletion()
    }

    init(
        coordinator: WorkflowCoordinator,
        sdSelectionController: SDSelectionController
    ) {
        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController(coordinator: coordinator)

        bindSDSelectionReadinessToWorkflowCompletion()
    }

    private func bindSDSelectionReadinessToWorkflowCompletion() {
        sdSelectionController.$readiness
            .dropFirst()
            .sink { [weak self] readiness in
                self?.updateSDCardSelectionCompletion(for: readiness)
            }
            .store(in: &cancellables)
    }

    private func updateSDCardSelectionCompletion(for readiness: SDCardReadiness?) {
        coordinator.invalidateWorkflow(after: .fixed(.sdCardSelection))
        coordinator.setWorkflowItem(
            .fixed(.sdCardSelection),
            isCompleted: readiness?.isReady == true
        )
    }

}
