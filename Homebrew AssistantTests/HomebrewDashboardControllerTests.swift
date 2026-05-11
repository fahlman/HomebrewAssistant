
//
//  HomebrewDashboardControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies Homebrew dashboard controller option visibility, filtering,
//  selection binding, and preparation status mapping.
//  Covers: Default filter/sort state, category filtering, alphabetical sorting,
//  internal workflow selection updates, and Wilbrand/HackMii status mapping.
//  Does not cover: Dashboard SwiftUI rendering, public recipe catalog loading,
//  downloads, staging, SD card writes, verification, or workflow navigation.
//

import Testing
import SwiftUI
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

    @Test func wilbrandStatusReflectsSelectionAndCompletion() {
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

        coordinator.setWorkflowItem(.internalWorkflow(.wilbrand), isCompleted: true)
        #expect(controller.status(for: wilbrandOption) == .readyToSave)
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
}

