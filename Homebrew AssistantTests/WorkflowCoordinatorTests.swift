//
//  WorkflowCoordinatorTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies generated workflow items, selection reachability, and
//  workflow reset behavior.
//  Covers: Initial visible fixed workflow generation, locked-step behavior, completed
//  item gating, selected internal/public recipe tracking, discarded generated-item
//  state, and reset-to-starting workflow behavior.
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
        #expect(!coordinator.canSelect(.fixed(.reviewSetup)))
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

    @Test func chooseHomebrewSelectionCompletesChooseHomebrewWithoutAddingForwardStep() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.select(.fixed(.chooseItems))

        #expect(coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!coordinator.canSelect(.fixed(.reviewSetup)))
        #expect(!coordinator.canGoForward)

        coordinator.updateSelectedInternalWorkflows([.wilbrand])
        coordinator.setWorkflowItem(.fixed(.chooseItems), isCompleted: true)

        #expect(coordinator.selectedInternalWorkflows == [.wilbrand])
        #expect(coordinator.isCompleted(.fixed(.chooseItems)))
        #expect(!coordinator.canGoForward)
    }

    @Test func selectedWilbrandIsTrackedButNotInsertedIntoGeneratedWorkflow() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.wilbrand])

        #expect(coordinator.selectedInternalWorkflows == [.wilbrand])
        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
    }


    @Test func selectedInternalWorkflowsAreTrackedButNotInsertedIntoGeneratedWorkflow() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.hackMii, .wilbrand])

        #expect(coordinator.selectedInternalWorkflows == [.wilbrand, .hackMii])
        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
    }

    @Test func removingSelectedInternalWorkflowUpdatesSelectionWithoutChangingGeneratedWorkflow() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.wilbrand, .hackMii])
        coordinator.updateSelectedInternalWorkflows([.hackMii])

        #expect(coordinator.selectedInternalWorkflows == [.hackMii])
        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
    }


    @Test func removingSelectedInternalWorkflowDiscardsItsStepState() {
        let coordinator = WorkflowCoordinator()
        let wilbrandItem = WorkflowItem.internalWorkflow(.wilbrand)

        coordinator.updateSelectedInternalWorkflows([.wilbrand])
        coordinator.updateSelectedInternalWorkflows([])

        #expect(coordinator.state(for: wilbrandItem).status == .notStarted)
        #expect(!coordinator.isCompleted(wilbrandItem))
    }

    @Test func resetWorkflowReturnsToStartingFixedWorkflowAndClearsGeneratedItemState() {
        let coordinator = WorkflowCoordinator()
        let sdCardItem = WorkflowItem.fixed(.sdCardSelection)
        let chooseItemsItem = WorkflowItem.fixed(.chooseItems)

        coordinator.updateSelectedInternalWorkflows([.wilbrand])
        coordinator.mark(sdCardItem, as: StepState(status: .completed))
        coordinator.mark(chooseItemsItem, as: StepState(status: .completed))
        coordinator.setWorkflowItem(sdCardItem, isCompleted: true)
        coordinator.setWorkflowItem(chooseItemsItem, isCompleted: true)

        coordinator.resetWorkflow()

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
        #expect(coordinator.selectedInternalWorkflows.isEmpty)
        #expect(coordinator.selectedPublicRecipes.isEmpty)
        #expect(coordinator.selectedItemID == sdCardItem.id)
        #expect(coordinator.state(for: sdCardItem).status == .notStarted)
        #expect(coordinator.state(for: chooseItemsItem).status == .notStarted)
        #expect(!coordinator.isCompleted(sdCardItem))
        #expect(!coordinator.isCompleted(chooseItemsItem))
    }
}
