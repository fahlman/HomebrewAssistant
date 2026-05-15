//
//  WorkflowSessionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and cross-controller state
//  synchronization.
//  Owns: WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  selected-step bottom-bar presentation state, navigation intent forwarding,
//  synchronization from SD card readiness into fixed workflow-step completion
//  state, and synchronization from dashboard completion into fixed workflow-step
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

    @Published private(set) var bottomBarConfiguration: WorkflowBottomBarConfiguration

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let coordinator = WorkflowCoordinator()
        let sdSelectionController = SDSelectionController()

        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController()
        self.bottomBarConfiguration = .automatic
        synchronizeBottomBarConfiguration()
        bindSelectedStepDisplayChanges()
        bindHomebrewDashboardActionBottomBarChanges()
        bindSDSelectionReadinessToWorkflowCompletion()
        bindHomebrewDashboardCompletionToWorkflowCompletion()
    }

    init(
        coordinator: WorkflowCoordinator,
        sdSelectionController: SDSelectionController
    ) {
        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController()
        self.bottomBarConfiguration = .automatic
        synchronizeBottomBarConfiguration()
        bindSelectedStepDisplayChanges()
        bindHomebrewDashboardActionBottomBarChanges()
        bindSDSelectionReadinessToWorkflowCompletion()
        bindHomebrewDashboardCompletionToWorkflowCompletion()
    }

    var canGoBack: Bool {
        coordinator.canGoBack
    }

    var canGoForward: Bool {
        coordinator.canGoForward
    }

    func goBack() {
        coordinator.goBack()
        synchronizeBottomBarConfiguration()
    }

    func goForward() {
        coordinator.goForward()
        synchronizeBottomBarConfiguration()
    }

    private func bindSelectedStepDisplayChanges() {
        coordinator.$selectedItemID
            .dropFirst()
            .sink { [weak self] _ in
                self?.synchronizeBottomBarConfiguration()
            }
            .store(in: &cancellables)
    }

    private func bindHomebrewDashboardActionBottomBarChanges() {
        homebrewDashboardController.$actionState
            .dropFirst()
            .sink { [weak self] _ in
                self?.synchronizeBottomBarConfiguration()
            }
            .store(in: &cancellables)
    }

    private func bindSDSelectionReadinessToWorkflowCompletion() {
        sdSelectionController.$readiness
            .dropFirst()
            .sink { [weak self] readiness in
                self?.synchronizeBottomBarConfiguration()
                self?.updateSDCardSelectionCompletion(for: readiness)
            }
            .store(in: &cancellables)
    }

    private func bindHomebrewDashboardCompletionToWorkflowCompletion() {
        homebrewDashboardController.$isComplete
            .dropFirst()
            .sink { [weak self] isCompleted in
                self?.updateChooseHomebrewCompletion(isCompleted: isCompleted)
                self?.synchronizeBottomBarConfiguration()
            }
            .store(in: &cancellables)
    }

    private func synchronizeBottomBarConfiguration() {
        bottomBarConfiguration = selectedStepBottomBarConfiguration
    }

    private var selectedStepBottomBarConfiguration: WorkflowBottomBarConfiguration {
        switch coordinator.selectedItem {
        case .fixed(.sdCardSelection):
            sdSelectionController.bottomBarConfiguration
        case .fixed(.chooseItems):
            homebrewDashboardController.bottomBarConfiguration
        case nil:
            .automatic
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
