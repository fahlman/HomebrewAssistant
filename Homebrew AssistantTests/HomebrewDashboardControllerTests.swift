//
//  HomebrewDashboardControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies Homebrew dashboard controller option visibility, filtering,
//  selection binding, and preparation status mapping.
//  Covers: Default filter/sort state, category filtering, alphabetical sorting,
//  internal workflow selection updates, initial Wilbrand/HackMii status mapping,
//  injected preparation-state status mapping, dashboard action-state selection,
//  bottom-bar configuration, and preparation action transitions.
//  Does not cover: Dashboard SwiftUI rendering, public recipe catalog loading,
//  downloads, staging, SD card writes, verification, or workflow navigation.
//

import Foundation
import Testing
internal import SwiftUI
@testable import Homebrew_Assistant

@MainActor
struct HomebrewDashboardControllerTests {
    @Test func defaultStateShowsInternalWorkflowOptionsInCategoryOrder() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)

        #expect(controller.selectedCategoryFilter == .all)
        #expect(controller.selectedSortMode == .category)
        #expect(controller.visibleOptions.map(\.source) == [
            .internalWorkflow(.wilbrand),
            .internalWorkflow(.hackMii)
        ])
    }

    @Test func categoryFilterLimitsVisibleOptions() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)

        controller.selectedCategoryFilter = .category(InternalWorkflowKind.wilbrand.category)

        #expect(controller.visibleOptions.map(\.source) == [.internalWorkflow(.wilbrand)])
    }

    @Test func alphabeticalSortOrdersVisibleOptionsByName() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)

        controller.selectedSortMode = .alphabetical

        let optionNames = controller.visibleOptions.map(\.name)
        #expect(optionNames == optionNames.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        })
    }

    @Test func bindingUpdatesSelectedInternalWorkflows() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true
        #expect(coordinator.selectedInternalWorkflows == [.hackMii])
        #expect(controller.binding(for: hackMiiOption).wrappedValue)

        controller.binding(for: hackMiiOption).wrappedValue = false
        #expect(coordinator.selectedInternalWorkflows.isEmpty)
        #expect(!controller.binding(for: hackMiiOption).wrappedValue)
    }

    @Test func wilbrandStatusReflectsSelection() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let wilbrandOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.wilbrand)
        }

        #expect(wilbrandOption != nil)
        guard let wilbrandOption else { return }

        #expect(controller.status(for: wilbrandOption) == .notSelected)

        controller.binding(for: wilbrandOption).wrappedValue = true
        #expect(controller.status(for: wilbrandOption) == .setupRequired)
    }

    @Test func hackMiiStatusReflectsSelection() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        #expect(controller.status(for: hackMiiOption) == .notSelected)

        controller.binding(for: hackMiiOption).wrappedValue = true
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func injectedPreparationStatusOverridesInitialStatusForSelectedOption() {
        let coordinator = WorkflowCoordinator()
        var preparationStateStore = HomebrewPreparationStateStore()
        preparationStateStore[InternalWorkflowKind.hackMii.id] = .downloading(progress: 0.5)
        let controller = HomebrewDashboardController(
            coordinator: coordinator,
            preparationStateStore: preparationStateStore
        )
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true

        #expect(controller.status(for: hackMiiOption) == .downloading(progress: 0.5))
    }

    @Test func deselectingAndReselectingOptionResetsPreparationStatus() {
        let coordinator = WorkflowCoordinator()
        var preparationStateStore = HomebrewPreparationStateStore()
        preparationStateStore[InternalWorkflowKind.hackMii.id] = .downloading(progress: 0.5)
        let controller = HomebrewDashboardController(
            coordinator: coordinator,
            preparationStateStore: preparationStateStore
        )
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true
        controller.binding(for: hackMiiOption).wrappedValue = false
        controller.binding(for: hackMiiOption).wrappedValue = true

        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func noSelectedHomebrewHasNothingSelectedActionState() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)

        #expect(controller.actionState == .nothingSelected)
    }

    @Test func nothingSelectedActionStateHasNoBottomBarAction() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)

        #expect(controller.bottomBarConfiguration.contextualActions.isEmpty)
        #expect(controller.bottomBarConfiguration.canGoForwardOverride == nil)
        #expect(controller.bottomBarConfiguration.defaultAction == nil)
    }

    @Test func selectedWilbrandNeedsWilbrandSetup() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let wilbrandOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.wilbrand)
        }

        #expect(wilbrandOption != nil)
        guard let wilbrandOption else { return }

        controller.binding(for: wilbrandOption).wrappedValue = true

        #expect(controller.actionState == .needsWilbrandSetup)
    }

    @Test func needsWilbrandSetupBottomBarUsesSetUpWilbrandAction() {
        let configuration = HomebrewDashboardActionState.needsWilbrandSetup.bottomBarConfiguration(
            controller: HomebrewDashboardController(coordinator: WorkflowCoordinator())
        )

        #expect(configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.setUpWilbrand.titleKey
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            HomebrewPreparationAction.setUpWilbrand.systemImageName
        ])
        #expect(configuration.canGoForwardOverride == false)
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func selectedHackMiiIsReadyToDownload() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true

        #expect(controller.actionState == .readyToDownload)
    }

    @Test func readyToDownloadBottomBarUsesDownloadAction() {
        let configuration = HomebrewDashboardActionState.readyToDownload.bottomBarConfiguration(
            controller: HomebrewDashboardController(coordinator: WorkflowCoordinator())
        )

        #expect(configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.download.titleKey
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            HomebrewPreparationAction.download.systemImageName
        ])
        #expect(configuration.canGoForwardOverride == false)
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func readyToSaveBottomBarUsesSaveAction() {
        let configuration = HomebrewDashboardActionState.readyToSave.bottomBarConfiguration(
            controller: HomebrewDashboardController(coordinator: WorkflowCoordinator())
        )

        #expect(configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.save.titleKey
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            HomebrewPreparationAction.save.systemImageName
        ])
        #expect(configuration.canGoForwardOverride == false)
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func wilbrandSetupTakesPriorityOverDownload() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let wilbrandOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.wilbrand)
        }
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(wilbrandOption != nil)
        #expect(hackMiiOption != nil)
        guard let wilbrandOption, let hackMiiOption else { return }

        controller.binding(for: wilbrandOption).wrappedValue = true
        controller.binding(for: hackMiiOption).wrappedValue = true

        #expect(controller.actionState == .needsWilbrandSetup)
    }

    @Test func performSetUpWilbrandMovesWilbrandToReadyToSave() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let wilbrandOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.wilbrand)
        }

        #expect(wilbrandOption != nil)
        guard let wilbrandOption else { return }

        controller.binding(for: wilbrandOption).wrappedValue = true
        controller.perform(.setUpWilbrand)

        #expect(controller.status(for: wilbrandOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performDownloadMovesReadyToDownloadOptionsToReadyToSave() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true
        controller.perform(.download)

        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performSaveMovesReadyToSaveOptionsToSaved() {
        let coordinator = WorkflowCoordinator()
        let controller = HomebrewDashboardController(coordinator: coordinator)
        let hackMiiOption = controller.visibleOptions.first { option in
            option.source == .internalWorkflow(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        controller.binding(for: hackMiiOption).wrappedValue = true
        controller.perform(.download)
        controller.perform(.save)

        #expect(controller.status(for: hackMiiOption) == .saved)
        #expect(controller.actionState == .complete)
    }

    @Test func completeActionStateHasNoBottomBarAction() {
        let configuration = HomebrewDashboardActionState.complete.bottomBarConfiguration(
            controller: HomebrewDashboardController(coordinator: WorkflowCoordinator())
        )

        #expect(configuration.contextualActions.isEmpty)
        #expect(configuration.canGoForwardOverride == nil)
        #expect(configuration.defaultAction == nil)
    }
}
