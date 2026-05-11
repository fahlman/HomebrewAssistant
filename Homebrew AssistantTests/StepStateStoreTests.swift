
//
//  StepStateStoreTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies per-workflow-item session state storage behavior.
//  Covers: Default missing-item state, storing and retrieving state, reset,
//  single-item removal, pruning to allowed item IDs, and preservation of stored
//  progress, selected option IDs, diagnostics, and recoverable error messages.
//  Does not cover: Workflow navigation, diagnostics recording, persistence,
//  scoped filesystem access, disk operations, downloads, or writes.
//

import Testing
@testable import Homebrew_Assistant

@MainActor
struct StepStateStoreTests {
    @Test func missingItemReturnsNotStartedState() {
        let store = StepStateStore()

        #expect(store[WorkflowItem.fixed(.sdCardSelection).id] == .notStarted)
    }

    @Test func subscriptStoresAndReturnsFullStepState() {
        var store = StepStateStore()
        let itemID = WorkflowItem.fixed(.chooseItems).id
        let state = StepState(
            status: .inProgress,
            progress: 0.5,
            selectedOptionIDs: ["wilbrand", "hackMii"],
            diagnosticMessages: ["Started", "Halfway"],
            recoverableErrorMessage: "Try again"
        )

        store[itemID] = state

        #expect(store[itemID] == state)
        #expect(store[itemID].status == .inProgress)
        #expect(store[itemID].progress == 0.5)
        #expect(store[itemID].selectedOptionIDs == ["wilbrand", "hackMii"])
        #expect(store[itemID].diagnosticMessages == ["Started", "Halfway"])
        #expect(store[itemID].recoverableErrorMessage == "Try again")
    }

    @Test func resetClearsStoredState() {
        var store = StepStateStore()
        let itemID = WorkflowItem.fixed(.chooseItems).id

        store[itemID] = StepState(status: .completed)
        store.reset()

        #expect(store[itemID] == .notStarted)
    }

    @Test func removeStateClearsOnlyRequestedItem() {
        var store = StepStateStore()
        let sdCardItemID = WorkflowItem.fixed(.sdCardSelection).id
        let chooseItemsItemID = WorkflowItem.fixed(.chooseItems).id

        store[sdCardItemID] = StepState(status: .completed)
        store[chooseItemsItemID] = StepState(status: .prepared)
        store.removeState(for: sdCardItemID)

        #expect(store[sdCardItemID] == .notStarted)
        #expect(store[chooseItemsItemID].status == .prepared)
    }

    @Test func removeStatesExceptAllowedItemIDsPrunesDiscardedItems() {
        var store = StepStateStore()
        let sdCardItemID = WorkflowItem.fixed(.sdCardSelection).id
        let chooseItemsItemID = WorkflowItem.fixed(.chooseItems).id
        let wilbrandItemID = WorkflowItem.internalWorkflow(.wilbrand).id

        store[sdCardItemID] = StepState(status: .completed)
        store[chooseItemsItemID] = StepState(status: .completed)
        store[wilbrandItemID] = StepState(status: .prepared)

        store.removeStates(except: [sdCardItemID, wilbrandItemID])

        #expect(store[sdCardItemID].status == .completed)
        #expect(store[chooseItemsItemID] == .notStarted)
        #expect(store[wilbrandItemID].status == .prepared)
    }
}

