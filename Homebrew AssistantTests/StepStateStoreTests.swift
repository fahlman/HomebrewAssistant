//
//  StepStateStoreTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies fixed workflow/sidebar item session state storage behavior.
//  Covers: Default missing-item state, storing and retrieving status/progress,
//  reset, single-item removal, and pruning to allowed item IDs.
//  Does not cover: Workflow navigation, homebrew preparation state, diagnostics,
//  persistence, scoped filesystem access, disk operations, downloads, or writes.
//

import Testing
@testable import Homebrew_Assistant

@MainActor
struct StepStateStoreTests {
    @Test func missingItemReturnsNotStartedState() {
        let store = StepStateStore()

        #expect(store[WorkflowItem.fixed(.sdCardSelection).id] == .notStarted)
    }

    @Test func subscriptStoresAndReturnsStepStatusAndProgress() {
        var store = StepStateStore()
        let itemID = WorkflowItem.fixed(.chooseItems).id
        let state = StepState(
            status: .inProgress,
            progress: 0.5
        )

        store[itemID] = state

        #expect(store[itemID] == state)
        #expect(store[itemID].status == .inProgress)
        #expect(store[itemID].progress == 0.5)
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
        store[chooseItemsItemID] = StepState(status: .inProgress)
        store.removeState(for: sdCardItemID)

        #expect(store[sdCardItemID] == .notStarted)
        #expect(store[chooseItemsItemID].status == .inProgress)
    }

    @Test func removeStatesExceptAllowedItemIDsPrunesDiscardedItems() {
        var store = StepStateStore()
        let sdCardItemID = WorkflowItem.fixed(.sdCardSelection).id
        let chooseItemsItemID = WorkflowItem.fixed(.chooseItems).id
        let discardedItemID = "discarded.generated.item"

        store[sdCardItemID] = StepState(status: .completed)
        store[chooseItemsItemID] = StepState(status: .completed)
        store[discardedItemID] = StepState(status: .inProgress)

        store.removeStates(except: [sdCardItemID, discardedItemID])

        #expect(store[sdCardItemID].status == .completed)
        #expect(store[chooseItemsItemID] == .notStarted)
        #expect(store[discardedItemID].status == .inProgress)
    }
}
