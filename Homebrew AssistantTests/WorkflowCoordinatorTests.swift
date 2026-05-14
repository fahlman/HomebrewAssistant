//
//  WorkflowCoordinatorTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies fixed workflow/sidebar items, selection reachability, and
//  workflow reset behavior.
//  Covers: Initial fixed workflow items, locked-step behavior, completed item
//  gating, fixed-item state pruning, and reset-to-starting workflow behavior.
//  Does not cover: UI rendering, SD card validation, scoped filesystem access,
//  downloads, staging, SD writes, or physical device behavior.
//
import Testing
@testable import Homebrew_Assistant

@MainActor
struct WorkflowCoordinatorTests {
    @Test func initialWorkflowContainsStartingFixedSteps() {
        let coordinator = WorkflowCoordinator()

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
    }

    @Test func futureStepsAreLockedUntilSDCardSelectionIsComplete() {
        let coordinator = WorkflowCoordinator()

        #expect(coordinator.canSelect(.fixed(.sdCardSelection)))
        #expect(!coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!coordinator.canGoForward)
    }

    @Test func completingSDCardSelectionUnlocksChooseHomebrew() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)

        #expect(coordinator.canSelect(.fixed(.chooseItems)))
        #expect(coordinator.canGoForward)
    }

    @Test func selectingLockedFutureStepDoesNothing() {
        let coordinator = WorkflowCoordinator()

        coordinator.select(.fixed(.chooseItems))

        #expect(coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
    }

    @Test func lockingSDCardSelectionAgainReturnsSelectionToReachableStep() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.select(.fixed(.chooseItems))
        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: false)

        #expect(coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
        #expect(!coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func completedChooseHomebrewDoesNotAddForwardStep() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.select(.fixed(.chooseItems))

        #expect(coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!coordinator.canGoForward)

        coordinator.setWorkflowItem(.fixed(.chooseItems), isCompleted: true)

        #expect(coordinator.isCompleted(.fixed(.chooseItems)))
        #expect(!coordinator.canGoForward)
    }

    @Test func resetWorkflowReturnsToStartingFixedWorkflowAndClearsFixedItemState() {
        let coordinator = WorkflowCoordinator()
        let sdCardItem = WorkflowItem.fixed(.sdCardSelection)
        let chooseItemsItem = WorkflowItem.fixed(.chooseItems)

        coordinator.mark(sdCardItem, as: StepState(status: .completed))
        coordinator.mark(chooseItemsItem, as: StepState(status: .completed))
        coordinator.setWorkflowItem(sdCardItem, isCompleted: true)
        coordinator.setWorkflowItem(chooseItemsItem, isCompleted: true)

        coordinator.resetWorkflow()

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
        #expect(coordinator.selectedItemID == sdCardItem.id)
        #expect(coordinator.state(for: sdCardItem).status == .notStarted)
        #expect(coordinator.state(for: chooseItemsItem).status == .notStarted)
        #expect(!coordinator.isCompleted(sdCardItem))
        #expect(!coordinator.isCompleted(chooseItemsItem))
    }
}
