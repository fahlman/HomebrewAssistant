//
//  WorkflowSessionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and cross-controller state
//  synchronization.
//  Owns: WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  selected-step display-change signaling, synchronization from SD card readiness
//  into fixed workflow-step completion state, and synchronization from dashboard
//  completion into fixed workflow-step completion state.
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
        self.homebrewDashboardController = HomebrewDashboardController()
        bindSelectedStepDisplayChanges()
        bindSDSelectionReadinessToWorkflowCompletion()
        configureDashboardCompletionHandler()
    }

    init(
        coordinator: WorkflowCoordinator,
        sdSelectionController: SDSelectionController
    ) {
        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController()
        bindSelectedStepDisplayChanges()
        bindSDSelectionReadinessToWorkflowCompletion()
        configureDashboardCompletionHandler()
    }

    private func bindSelectedStepDisplayChanges() {
        coordinator.$selectedItemID
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func bindSDSelectionReadinessToWorkflowCompletion() {
        sdSelectionController.$readiness
            .dropFirst()
            .sink { [weak self] readiness in
                self?.objectWillChange.send()
                self?.updateSDCardSelectionCompletion(for: readiness)
            }
            .store(in: &cancellables)
    }

    private func configureDashboardCompletionHandler() {
        homebrewDashboardController.onCompletionStateChanged = { [weak self] isCompleted in
            self?.objectWillChange.send()
            self?.updateChooseHomebrewCompletion(isCompleted: isCompleted)
        }
    }

    private func updateSDCardSelectionCompletion(for readiness: SDCardReadiness?) {
        let isCompleted = readiness?.isReady == true
        guard coordinator.isCompleted(.fixed(.sdCardSelection)) != isCompleted else {
            return
        }

        coordinator.invalidateWorkflow(after: .fixed(.sdCardSelection))
        coordinator.setWorkflowItem(
            .fixed(.sdCardSelection),
            isCompleted: isCompleted
        )
    }

    private func updateChooseHomebrewCompletion(isCompleted: Bool) {
        guard coordinator.isCompleted(.fixed(.chooseItems)) != isCompleted else {
            return
        }

        coordinator.setWorkflowItem(
            .fixed(.chooseItems),
            isCompleted: isCompleted
        )
    }
}
