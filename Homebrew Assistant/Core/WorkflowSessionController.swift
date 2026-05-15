//
//  WorkflowSessionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and cross-controller state
//  synchronization.
//  Owns: WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  selected-step bottom-bar state snapshots, navigation intent forwarding,
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

    @Published private(set) var bottomBarState: WorkflowBottomBarState

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let coordinator = WorkflowCoordinator()
        let sdSelectionController = SDSelectionController()

        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController()
        self.bottomBarState = .initial
        synchronizeBottomBarState()
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
        self.bottomBarState = .initial
        synchronizeBottomBarState()
        bindSelectedStepDisplayChanges()
        bindHomebrewDashboardActionBottomBarChanges()
        bindSDSelectionReadinessToWorkflowCompletion()
        bindHomebrewDashboardCompletionToWorkflowCompletion()
    }

    func goBack() {
        coordinator.goBack()
        synchronizeBottomBarState()
    }

    func goForward() {
        coordinator.goForward()
        synchronizeBottomBarState()
    }

    private func bindSelectedStepDisplayChanges() {
        coordinator.$selectedItemID
            .dropFirst()
            .sink { [weak self] _ in
                self?.synchronizeBottomBarState()
            }
            .store(in: &cancellables)
    }

    private func bindHomebrewDashboardActionBottomBarChanges() {
        homebrewDashboardController.$actionState
            .dropFirst()
            .sink { [weak self] actionState in
                self?.synchronizeBottomBarState(dashboardActionState: actionState)
            }
            .store(in: &cancellables)
    }

    private func bindSDSelectionReadinessToWorkflowCompletion() {
        sdSelectionController.$readiness
            .dropFirst()
            .sink { [weak self] readiness in
                self?.updateSDCardSelectionCompletion(for: readiness)
                self?.synchronizeBottomBarState(sdReadiness: readiness)
            }
            .store(in: &cancellables)
    }

    private func bindHomebrewDashboardCompletionToWorkflowCompletion() {
        homebrewDashboardController.$isComplete
            .dropFirst()
            .sink { [weak self] isCompleted in
                self?.updateChooseHomebrewCompletion(isCompleted: isCompleted)
                self?.synchronizeBottomBarState()
            }
            .store(in: &cancellables)
    }

    private func synchronizeBottomBarState(
        sdReadiness: SDCardReadiness? = nil,
        dashboardActionState: HomebrewDashboardActionState? = nil
    ) {
        bottomBarState = WorkflowBottomBarState(
            canGoBack: coordinator.canGoBack,
            canGoForward: coordinator.canGoForward,
            configuration: selectedStepBottomBarConfiguration(
                sdReadiness: sdReadiness,
                dashboardActionState: dashboardActionState
            )
        )
    }

    private func selectedStepBottomBarConfiguration(
        sdReadiness: SDCardReadiness? = nil,
        dashboardActionState: HomebrewDashboardActionState? = nil
    ) -> WorkflowBottomBarConfiguration {
        switch coordinator.selectedItem {
        case .fixed(.sdCardSelection):
            if let sdReadiness {
                return sdSelectionController.bottomBarConfiguration(for: sdReadiness)
            }

            return sdSelectionController.bottomBarConfiguration
        case .fixed(.chooseItems):
            if let dashboardActionState {
                return homebrewDashboardController.bottomBarConfiguration(for: dashboardActionState)
            }

            return homebrewDashboardController.bottomBarConfiguration
        case nil:
            return .automatic
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
